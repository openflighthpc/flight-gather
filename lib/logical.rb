def logical_data
  data = {}
  
  # Get interface info
  data[:network] = {}
  ::Dir::entries('/sys/class/net').reject! {|x| x =~ /\.|\.\.|lo/i }.sort.each do |interface|
    data[:network][interface] = {} unless data[:network].key?(interface)
    data[:network][interface][:ip] = between(`nmcli -t device show #{interface}`, "IP4.ADDRESS[1]:", "\n")
  end
  
  if !`command -v ipmitool`.empty?
    addr=`ipmitool lan print 1 | grep -e "IP Address" | grep -vi "Source"| awk '{ print $4 }'`.chomp rescue nil
    data[:bmcip]= addr unless addr.to_s.empty? 
    mac=`ipmitool lan print 1 | grep 'MAC Address' | awk '{ print $4 }'`.chomp rescue nil
    data[:bmcmac] = mac unless mac.to_s.empty?
  end

  # Get platform info
  sysInfo = `dmidecode -t system`.downcase
  if sysInfo.include? "openstack"
    data[:platform] = "OpenStack"
  elsif sysInfo.include? "amazon"
    data[:platform] = "AWS"
  elsif sysInfo.include? "azure"
    data[:platform] = "Azure"
  else
    data[:platform] = "Metal"
  end
 
  data
end
