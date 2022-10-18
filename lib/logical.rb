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

def logical_data
  data = {}
  
  # Get interface info
  data[:network] = {}
  ::Dir::entries('/sys/class/net').reject! {|x| x =~ /\.|\.\.|lo/i }.sort&.each do |interface|
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
