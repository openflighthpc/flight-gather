#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
#
# This file is part of flight-gather.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# flight-gather is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with flight-gather. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on flight-gather, please visit:
# https://github.com/openflighthpc/flight-gather
#==============================================================================

def physical_data
  data = {}
  
  # Get system info
  
  data[:model] = `dmidecode -s system-product-name`.chomp
  data[:bios] = `dmidecode -s bios-version`.chomp
  data[:serial] = `dmidecode -s system-serial-number`.chomp
  data[:ram] = `grep MemTotal /proc/meminfo | awk '{print $2}'`.chomp # RAM measured in kB
  
  # Get processor info
  
  data[:cpus] = {}
  procInfo = `dmidecode -q -t processor`.split("Processor Information")[1..-1]
  procInfo.each do |proc|
    data[:cpus][between(proc, "Socket Designation: ", "\n").delete(" ")] = { id: between(proc, "ID: ", "\n",),
                                                                             model: between(proc, "Version: ", "\n",),
                                                                             cores: [between(proc, "Thread Count: ", "\n").to_i, 1].max,
                                                                             hyperthreading: `cat /sys/devices/system/cpu/smt/active`=="1\n"
                                                                           }
    
  end
  
  # Get interface info
  
  data[:network] = {}
  ::Dir::entries('/sys/class/net').reject! {|x| x =~ /\.|\.\.|lo/i }.sort.each do |interface|
    data[:network][interface] = {} unless data[:network].key?(interface)
    data[:network][interface][:mac] = `nmcli -t device show #{interface} | grep HWADDR`[15..31]
    data[:network][interface][:speed] = `ethtool #{interface} | grep Speed | awk '{print $2}'`.chomp
  end
  
  # Get info from cmdline
  
  cmdline = ::File::read('/proc/cmdline').split.map { |a| h=a.split('='); [h.first,h.last] if h.size == 2}.compact.to_h
  data[:sysuuid] = cmdline['SYSUUID']
  data[:bootif] = cmdline['BOOTIF']
  
  # Get disk info
  
  data[:disks] = {}
  diskText = `lsblk -d`.split("\n").drop(1)
  diskText.each do |disk|
    diskData = disk.split
    data[:disks][diskData[0]] = {size: diskData[3]}
  end
  
  # Get GPU info
  
  data[:gpus] = {}
  gpus = Hash.from_xml(`lshw -C display -xml`)["list"]["node"]
  gpus = [gpus].flatten(1) # convert to singleton array if not an array already
  gpus.each_with_index do |gpu, index|
    data[:gpus]["GPU #{index}"] = { name: gpu["product"],
                                    slot: gpu["handle"]
                                  }
  end
  data
end
