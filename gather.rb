#!/usr/bin/ruby -w

require "yaml"
require "optparse"
require "active_support"
require "active_support/core_ext/hash"
require "pp" # just for debugging

def between(string, s1, s2) # Returns the contents of string between the last instance of s1 and the next subsequent instance of s2
  if string.include? s1 and string.split(s1).last.include? s2
    string.split(s1).last.split(s2).first
  else ""
  end
end

# Set command line options
options = { name: "data.yml",
            dir: "./",
            physical: true,
            logical: true}
OptionParser.new do |opts|
  opts.banner = "A tool to gather system information for a node.\nUsage: gather.rb [options]"
  opts.on("-p", "--primary PRIMARYGROUPS", "Primary group for the node") { |o| options[:pri] = o }
  opts.on("-g", "--groups x,y,z", Array, "Comma-separated list of secondary groups for the node") { |o| options[:sec] = o }
  opts.on("-n", "--name FILENAME", "Name of exported YAML file, defaults to data.yml") { |o| if o[-4..-1] == ".yml" then options[:name] = o else options[:name] = o + ".yml" end }
  opts.on("-d", "--directory DIRECTORY", "Directory to save output to, defaults to current directory") { |o| options[:dir] = o }
  opts.on("-t", "--types x,y,z", Array, "Type of check to run (physical or logical), if not provided then both types are collected") { |o| 
                                                                                                                                       options[:physical] = o.include? "physical"
                                                                                                                                       options[:logical] = o.include? "logical"
                                                                                                                                     }
end.parse!

data = { primaryGroup: options[:pri],
         secondaryGroups: options[:sec]
       }

# Get system info
if options[:physical]
  data[:model] = `dmidecode -s system-product-name`.chomp
  data[:bios] = `dmidecode -s bios-version`.chomp
  data[:serial] = `dmidecode -s system-serial-number`.chomp
  data[:ram] = `grep MemTotal /proc/meminfo | awk '{print $2}'`.chomp # RAM measured in kB
end

# Get processor info
if options[:physical]
  data[:cpus] = {}
  procInfo = `dmidecode -q -t processor`.split("Processor Information")[1..-1]
  procInfo.each do |proc|
    data[:cpus][between(proc, "Socket Designation: ", "\n")] = { id: between(proc, "ID: ", "\n",),
                                                                 model: between(proc, "Version: ", "\n",),
                                                                 cores: [between(proc, "Thread Count: ", "\n").to_i, 1].max,
                                                                 hyperthreading: `cat /sys/devices/system/cpu/smt/active`=="1\n"
                                                               }
    
  end
end

# Get interface info
data[:network] = {}
::Dir::entries('/sys/class/net').reject! {|x| x =~ /\.|\.\.|lo/i }.sort.each do |interface|
  data[:network][interface] = {}
  data[:network][interface][:ip] = between(`nmcli -t device show #{interface}`, "IP4.ADDRESS[1]:", "\n") unless !options[:logical]
  data[:network][interface][:mac] = `nmcli -t device show #{interface} | grep HWADDR`[15..31] unless !options[:physical]
  data[:network][interface][:speed] = `ethtool #{interface} | grep Speed | awk '{print $2}'`.chomp unless !options[:physical]
end

# Get BMC info
if !`command -v ipmitool`.empty? and options[:logical]
  addr=`ipmitool lan print 1 | grep -e "IP Address" | grep -vi "Source"| awk '{ print $4 }'`.chomp rescue nil
  data[:bmcip]= addr unless addr.to_s.empty? 
  mac=`ipmitool lan print 1 | grep 'MAC Address' | awk '{ print $4 }'`.chomp rescue nil
  data[:bmcmac] = mac unless mac.to_s.empty?
end

# Get info from cmdline
if options[:physical]
  cmdline = ::File::read('/proc/cmdline').split.map { |a| h=a.split('='); [h.first,h.last] if h.size == 2}.compact.to_h
  data[:sysuuid] = cmdline['SYSUUID']
  data[:bootif] = cmdline['BOOTIF']
end

# Get disk size
if options[:physical]
  data[:disks] = {}
  diskText = `lsblk -d`.split("\n").drop(1)
  diskText.each do |disk|
    diskData = disk.split
    data[:disks][diskData[0]] = {size: diskData[3]}
  end
end

# Get GPU info
if options[:physical]
  data[:gpus] = {}
  gpus = Hash.from_xml(`lshw -C display -xml`)["list"]["node"]
  gpus = [gpus].flatten(1) # convert to singleton array if not an array already
  gpus.each_with_index do |gpu, index|
    data[:gpus]["GPU #{index}"] = { name: gpu["product"],
                                    slot: gpu["handle"]
                                  }
  end
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

begin
  File.open(options[:dir]+options[:name], "w") { |file| file.write(data.to_yaml) }
rescue Errno::ENOENT
  puts "Invalid directory, defaulting to this directory"
  File.open("./data.yml", "w") { |file| file.write(data.to_yaml) }
end
