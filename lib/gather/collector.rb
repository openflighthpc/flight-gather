# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2023-present Alces Flight Ltd.
#
# This file is part of Flight Gather.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Gather is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Gather. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Gather, please visit:
# https://github.com/openflighthpc/flight-gather
#==============================================================================

require 'socket'
require 'yaml'
require 'json'

module Gather
  class Collector
    def self.physical_data
      data = {}

      # Get system info

      data[:model] = `dmidecode -s system-product-name`.chomp
      data[:bios] = `dmidecode -s bios-version`.chomp
      data[:serial] = `dmidecode -s system-serial-number`.chomp

      # Get RAM info

      data[:ram] = {}
      ram_info = `dmidecode -q -t 17`.split('Memory Device')[1..]
      data[:ram][:total_capacity] = si_to_bytes(between(`lshw -quiet -c memory 2>/dev/null |grep -A 5 '*-memory' |grep size`, 'size: ', "\n")) / (1000.0 ** 3)
      data[:ram][:units] = ram_info&.reject {|x| x.include?('No Module Installed')}&.size
      data[:ram][:capacity_per_unit] = data[:ram][:total_capacity] / data[:ram][:units]
      data[:ram][:ram_data] = {}
      ram_info&.reject {|x| x.include?('No Module Installed')}&.each&.with_index() do |device, index|
        data[:ram][:ram_data]["RAM#{index}"] = { form_factor: between(device, 'Form Factor: ', "\n"),
                                                 size: si_to_bytes(between(device, 'Size: ', "\n")) / (1000.0 ** 3),
                                                 locator: between(device, "\tLocator: ", "\n") }
      end

      # Get processor info

      data[:cpus] = {}
      proc_info = `dmidecode -q -t processor`.split('Processor Information')[1..]
      data[:cpus][:units] = proc_info&.size
      data[:cpus][:cores_per_cpu] = [between(proc_info&.first, 'Thread count: ', "\n").to_i, 1].max
      data[:cpus][:cpu_data] = {}
      proc_info&.each&.with_index() do |proc, index|
        data[:cpus][:cpu_data]["CPU#{index}"] = { socket: between(proc, 'Socket Designation: ', "\n"),
                                                  model: between(`grep -m 1 '^model name' /proc/cpuinfo |sed 's/ @.*//g'`, "model name\t: ", "\n"),
                                                  cores: [between(proc, 'Core Count: ', "\n").to_i, 1].max,
                                                  hyperthreading: `cat /sys/devices/system/cpu/smt/active` == "1\n" }
      end

      # Get interface info

      data[:network] = {}
      ::Dir.entries('/sys/class/net').reject! { |x| x =~ /\.|\.\.|lo/i }.sort&.each do |interface|
        data[:network][interface] = {} unless data[:network].key?(interface)
        data[:network][interface][:mac] = `nmcli -t device show #{interface} | grep HWADDR`[15..31]
        data[:network][interface][:speed] = `ethtool #{interface} | grep Speed | awk '{print $2}'`.chomp
      end

      # Get info from cmdline

      cmdline = ::File.read('/proc/cmdline').split.map do |a|
        h = a.split('=')
        [h.first, h.last] if h.size == 2
      end.compact.to_h
      data[:sysuuid] = cmdline['SYSUUID']
      data[:bootif] = cmdline['BOOTIF']

      # Get disk info

      data[:disks] = {}
      disk_data = JSON.parse(`lsblk -e7 -d -o +ROTA --json`)
      disk_data['blockdevices'].each do |disk|
        data[:disks][disk['name']] = { type: disk['rota'] ? 'hdd' : 'ssd',
                                       size: si_to_bytes(disk['size']) / (1000.0 ** 3) }
      end

      # Get GPU info

      data[:gpus] = {}
      gpus = Hash.from_xml(`lshw -C display -xml`)['list']
      if gpus != "\n"
        gpus = gpus['node']
        gpus = [gpus].flatten(1) # convert to singleton array if not an array already
        gpus&.each_with_index do |gpu, index|
          data[:gpus]["GPU#{index}"] = { name: gpu['product'],
                                         slot: gpu['handle'] }
        end
      end

      data
    end

    def self.logical_data
      data = {}

      # Get interface info
      data[:network] = {}
      ::Dir.entries('/sys/class/net').reject! { |x| x =~ /\.|\.\.|lo/i }.sort&.each do |interface|
        data[:network][interface] = {} unless data[:network].key?(interface)
        data[:network][interface][:ip] = between(`nmcli -t device show #{interface}`, 'IP4.ADDRESS[1]:', "\n")
      end

      if system('command -v ipmitool')
        addr = begin
          `ipmitool lan print 1 | grep -e "IP Address" | grep -vi "Source"| awk '{ print $4 }'`.chomp
        rescue StandardError
          nil
        end
        data[:bmcip] = addr unless addr.to_s.empty?
        mac = begin
          `ipmitool lan print 1 | grep 'MAC Address' | awk '{ print $4 }'`.chomp
        rescue StandardError
          nil
        end
        data[:bmcmac] = mac unless mac.to_s.empty?
      end

      # Get platform info
      sys_info = `dmidecode -t system`.downcase
      data[:platform] = if sys_info.include? 'openstack'
                          'OpenStack'
                        elsif sys_info.include? 'amazon'
                          'AWS'
                        elsif sys_info.include? 'microsoft'
                          'Azure'
                        else
                          'Metal'
                        end

      data
    end

    # Returns the contents of string between the last instance of s1 and the next subsequent instance of s2
    def self.between(string, s1, s2)
      if string.include?(s1) && string.split(s1).last.include?(s2)
        string.split(s1).last.split(s2).first
      else
        ''
      end
    end

    def self.si_to_bytes(si_string)
      units = ['', 'k', 'M', 'G', 'T', 'P']
      value = si_string.scan(/\d+/).first
      unit = si_string.split(value).last.to_s.strip[0]
      return value.to_i * 1000 ** (units.index(unit).to_i)
    end
  end
end
