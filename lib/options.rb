require "optparse"

def get_options
  options = { name: "data.yml",
              dir: File.expand_path('..', __dir__),
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
  options
end
