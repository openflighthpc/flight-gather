#!/usr/bin/ruby -w

require "yaml"
require "optparse"
require "socket"
require "active_support"
require "active_support/core_ext/hash"
require "json"
require "pp"

# Set command line options
options = {}
OptionParser.new do |opts|
  opts.banner = "A tool to gather system information for a node.\nUsage: gather.rb [options]"
  opts.on("-p", "--primary PRIMARYGROUPS", "Primary group for the node") { |o| options[:pri] = o }
  opts.on("-g", "--groups GROUP1,GROUP2,GROUP3", Array, "Comma-separated list of secondary groups for the node") { |o| options[:sec] = o }
  opts.on("-n", "--name FILENAME", "Name of exported YAML file") { |o| options[:name] = o }
end.parse!

data = { system: { model: "NULL",
                   bios: "NULL",
                   serial: "NULL",
                   cpus: {},
                   gpus: {},
                   ram: "NULL",
                   cloud: "NULL",
                   primaryGroup: options[:pri],
                   secondaryGroups: options[:sec]
                 },
                   
         network: {},
         disks: {}
        }

# Get system info
data[:system][:model] = `dmidecode -s system-product-name`.delete("\n")
data[:system][:bios] = `dmidecode -s bios-version`.delete("\n")
data[:system][:serial] = `dmidecode -s system-serial-number`.delete("\n")
data[:system][:ram] = `grep MemTotal /proc/meminfo | awk '{print $2}'`.delete("\n") # RAM measured in kB

# Get processor info
procIds = `dmidecode -q -t processor | grep "ID:"`.delete("\t").split("\n").map{ |x| x[4..] } # collect CPU IDs into array
procInfo = JSON.parse(`lscpu -J`)["lscpu"]
procIds.each do |id|
  data[:system][:cpus][id] = {}
  procInfo.each do |setting|
    if setting["field"] == "Model name:"
      data[:system][:cpus][id][:model] = setting["data"]
    elsif setting["field"] == "Core(s) per socket:"
      data[:system][:cpus][id][:cores] = setting["data"].to_i
    end
    data[:system][:cpus][id][:slot] = `dmidecode -q -t processor | grep "Socket Designation:"`[21..-2]
  end
end

# Get interface info
ifs = Socket.getifaddrs.select { |x| x.addr.ipv4?}
ifs.each do |interface|
  data[:network][interface.name] = { ip: interface.addr.ip_address,
                                     mac: `nmcli -t device show #{interface.name} | grep HWADDR`[15..31],
                                     speed: `ethtool #{interface.name} | grep Speed | awk '{print $2}'`.delete("\n")
                                   }
end

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
  data[:system][:gpus]["GPU #{index}"] = { name: gpu["product"],
                                           slot: gpu["handle"]
                                         }
end

# Get cloud platform info
sysInfo = `dmidecode -t system`.downcase
if sysInfo.include? "openstack"
  data[:system][:cloud] = "OpenStack"
elsif sysInfo.include? "amazon"
  data[:system][:cloud] = "AWS"
elsif sysInfo.include? "azure"
  data[:system][:cloud] = "Azure"
else
  data[:system][:cloud] = "Unrecognised cloud platform"
end

File.open("./#{options[:name]}.yml", "w") { |file| file.write(data.to_yaml) }
