module FlightGather
  def self.root
    File.expand_path('..', __dir__)
  end
end

$LOAD_PATH.unshift(File.join(FlightGather.root, "lib"), File.join(FlightGather.root, "helpers"))

require "physical"
require "logical"
require "between"
require "options"

require "yaml"
require "active_support"
require "active_support/core_ext/hash"
require "pp"
require "rubygems"
require "commander"

#module FlightGather
#  def self.collect
#    puts "Beginning data gather..."
#
#    options = get_options
#
#    data = { primaryGroup: options[:pri],
#             secondaryGroups: options[:sec]
#           }
#
#    if options[:physical]
#      puts "Gathering physical data..."
#      data = data.deep_merge(physical_data)
#    end
#
#    if options[:logical]
#      puts "Gathering logical data..."
#      data = data.deep_merge(logical_data)
#    end
#
#    begin
#      File.open(File.join(options[:dir], options[:name]), "w") { |file| file.write(data.to_yaml) }
#      puts "Written to " + File.join(options[:dir], options[:name])
#    rescue Errno::ENOENT
#      puts "Invalid directory, defaulting to current directory"
#      File.open("./" + options[:name], "w") { |file| file.write(data.to_yaml) }
#      puts "Written to " + File.join(root, options[:name])
#    end
#    puts "Done!"
#  end
#end

module FlightGather
  extend Commander::Delegates
  
  program :name, "gather"
  program :version, "1.0.0"
  program :description, "Tool for gathering system information"
  default_command :help

  command "gather" do |c|
    c.syntax = "gather [options]"
    c.description = "Gathers physical and/or logical system information"
    c.option "--primary PRIMARYGROUPS", String, "Primary group for the node"
    c.option "--groups x,y,z", Array, "Comma-separated list of secondary groups for the node"
    c.option "--types x,y,z", Array, "Type of check to run (physical or logical), if not provided then both types are collected"
    
    c.action do |args, options|
      options.default types: ["physical","logical"]
      options.physical = options.types.include? "physical"
      options.logical = options.types.include? "logical"
      
      puts "Beginning data gather..."

      data = { primaryGroup: options.primary,
               secondaryGroups: options.secondary
             }

      if options.types.include? "physical"
        puts "Gathering physical data..."
        data = data.deep_merge(physical_data)
      end

      if options.types.include? "logical"
        puts "Gathering logical data..."
        data = data.deep_merge(logical_data)
      end
      File.open(File.join(root, "lib/buffer.yml"), "w") { |file| file.write(data.to_yaml) }
      puts "Data gathered. Use 'show' to review data, or 'save' to save to chosen directory"
    end
  end
  
  command "show" do |c|
    c.syntax = "show"
    c.action do |args, options|
      begin
        File.open(File.join(root, "lib/buffer.yml")) { |file| puts file.read }
      rescue Errno::ENOENT
        puts "System info not yet gathered, try running 'gather' first"
      end
    end
  end
  
  command "modify" do |c|

  command "save" do |c|
    c.syntax = "save [options]"
    c.option "--name FILENAME", String, "Name of exported YAML file, defaults to data.yml"
    c.option "--directory DIRECTORY", String, "Directory to save output to, defaults to current directory"
    
    c.action do |args, options|
      options.default name: "data.yml",
                      directory: self.root
      begin
        File.open(File.join(root, "lib/buffer.yml")) { |bufferFile|
          begin
            File.open(File.join(options.directory, options.name), "w") { |file| file.write(bufferFile.read) }
            puts "Written to " + File.join(options.directory, options.name)
          rescue Errno::ENOENT
            puts File.join(options.directory, options.name)
            puts "Invalid directory, defaulting to current directory"
            File.open("./" + options.name, "w") { |file| file.write(bufferFile.to_yaml) }
            puts "Saved to " + File.join(root, options[:name])
          end
        }
      rescue Errno::ENOENT
        puts "System info not yet gathered, try running 'gather' first"
      end
    end
  end
end

FlightGather.run!
