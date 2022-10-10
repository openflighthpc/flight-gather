root = File.expand_path('..', __dir__)

$LOAD_PATH.unshift(File.join(root, "lib"), File.join(root, "helpers"))
require "physical"
require "logical"
require "between"
require "options"

require "yaml"
require "active_support"
require "active_support/core_ext/hash"
require "pp"

module FlightGather
  def self.collect
    puts "Beginning data gather..."

    options = get_options

    data = { primaryGroup: options[:pri],
                  secondaryGroups: options[:sec]
                }

    if options[:physical]
      puts "Gathering physical data..."
      data = data.deep_merge(physical_data)
    end

    if options[:logical]
      puts "Gathering logical data..."
      data = data.deep_merge(logical_data)
    end

    begin
      File.open(File.join(options[:dir], options[:name]), "w") { |file| file.write(data.to_yaml) }
      puts "Written to " + File.join(options[:dir], options[:name])
    rescue Errno::ENOENT
      puts "Invalid directory, defaulting to current directory"
      File.open("./" + options[:name], "w") { |file| file.write(data.to_yaml) }
      puts "Written to " + File.join(root, options[:name])
    end
    puts "Done!"
  end
end  
  
FlightGather.collect

