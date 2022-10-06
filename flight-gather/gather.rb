#!/usr/bin/ruby -w

require "yaml"
require "optparse"
require "socket"
require "active_support"
require "active_support/core_ext/hash"
require "pp" # just for debugging

def between(string, s1, s2) # Returns the contents of string between the last instance of s1 and the next subsequent instance of s2
  string.split(s1).last.split(s2).first
end

# Set command line options
options = { name: "data",
            dir: "./"}
OptionParser.new do |opts|
  opts.banner = "A tool to gather system information for a node.\nUsage: gather.rb [options]"
  opts.on("-p", "--primary PRIMARYGROUPS", "Primary group for the node") { |o| options[:pri] = o }
  opts.on("-g", "--groups x,y,z", Array, "Comma-separated list of secondary groups for the node") { |o| options[:sec] = o }
  opts.on("-n", "--name ", "Name of exported YAML file, defaults to ") { |o| options[:name] = o }
  opts.on("-d", "--directory DIRECTORY", "Directory to save output to, defaults to current directory") { |o| options[:dir] = o }
end.parse!

data = { model: "NULL",
         bios: "NULL",
         serial: "NULL",
         cpus: {},
         gpus: {},
         ram: "NULL",
         cloud: "NULL",
         primaryGroup: options[:pri],
         secondaryGroups: options[:sec],
         network: {},
         disks: {},
         bmcip: "Not found",
         bmcmac: "Not found",
         sysuid: "NULL",
         bootif: "NULL"
        }

# Get system info
data[:model] = `dmidecode -s system-product-name`.delete("\n")
data[:bios] = `dmidecode -s bios-version`.delete("\n")
data[:serial] = `dmidecode -s system-serial-number`.delete("\n")
data[:ram] = `grep MemTotal /proc/meminfo | awk '{print $2}'`.delete("\n") # RAM measured in kB

# Get processor info
procInfo = `dmidecode -q -t processor`.split("Processor Information")[1..]
procInfo.each do |proc|
  data[:cpus][between(proc, "Socket Designation: ", "\n")] = { id: between(proc, "ID: ", "\n",),
                                                               model: between(proc, "Version: ", "\n",),
                                                               cores: [between(proc, "Thread Count: ", "\n").to_i, 1].max,
                                                               hyperthreading: `cat /sys/devices/system/cpu/smt/active`=="1\n"
                                                             }
  
end

# Get interface info
ifs = Socket.getifaddrs.select { |x| x.addr and x.addr.ipv4?}
ifs.each do |interface|
  data[:network][interface.name] = { ip: interface.addr.ip_address,
                                     mac: `nmcli -t device show #{interface.name} | grep HWADDR`[15..31],
                                     speed: `ethtool #{interface.name} | grep Speed | awk '{print $2}'`.delete("\n")
                                   }
end

# Get BMC info
addr=`ipmitool lan print 1 | grep -e "IP Address" | grep -vi "Source"| awk '{ print $4 }'`.chomp rescue nil
data[:bmcip]= addr unless addr.to_s.empty? 
mac=`ipmitool lan print 1 | grep 'MAC Address' | awk '{ print $4 }'`.chomp rescue nil
data[:bmcmac] = mac unless mac.to_s.empty?

# Get info from cmdline
cmdline = ::File::read('/proc/cmdline').split.map { |a| h=a.split('='); [h.first,h.last] if h.size == 2}.compact.to_h
data[:sysuuid] = cmdline['SYSUUID']
data[:bootif] = cmdline['BOOTIF']

# Get disk size
diskText = `lsblk -d`.split("\n").drop(1)
diskText.each do |disk|
  diskData = disk.split
  data[:disks][diskData[0]] = {size: diskData[3]}
end

# Get GPU info
gpus = Hash.from_xml(`lshw -C display -xml`)["list"]["node"]
gpus = [gpus].flatten(1) # convert to singleton array if not an array already
gpus.each_with_index do |gpu, index|
  data[:gpus]["GPU #{index}"] = { name: gpu["product"],
                                  slot: gpu["handle"]
                                }
end

# Get cloud platform info
sysInfo = `dmidecode -t system`.downcase
if sysInfo.include? "openstack"
  data[:cloud] = "OpenStack"
elsif sysInfo.include? "amazon"
  data[:cloud] = "AWS"
elsif sysInfo.include? "azure"
  data[:cloud] = "Azure"
else
  data[:cloud] = "Not on a cloud platform"
end

File.open(options[:dir]+options[:name]+".yml", "w") { |file| file.write(data.to_yaml) }
