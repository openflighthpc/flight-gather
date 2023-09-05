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
require 'active_support'
require 'active_support/core_ext/hash'

require_relative '../command'
require_relative '../collector'
require_relative '../config'

module Gather
  module Commands
    class Collect < Command
      def run

        puts @options.type.inspect
        if @options.type && (!["physical", "logical"].include? @options.type.downcase) then
          raise "Invalid data type, must be 'physical' or 'logical'"
        end

        puts "Beginning data gather..."

        data = { primaryGroup: @options.primary,
                 secondaryGroups: @options.groups
               }

        if @options.type.nil? || @options.type.downcase == "physical"
          puts "Gathering physical data..."
          data = data.deep_merge(Collector.physical_data)
        end

        if @options.type.nil? || @options.type.downcase == "logical"
          puts "Gathering logical data..."
          data = data.deep_merge(Collector.logical_data)
        end
        File.open(File.join(Config.data_path, "data.yaml"), "w") { |file| file.write(data.to_yaml) }
        puts "Data gathered and written to " + Config.data_path
      end
    end
  end
end
