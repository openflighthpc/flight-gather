# frozen_string_literal: true

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
require_relative '../command'
require_relative '../config'
require 'yaml'

module Gather
  module Commands
    class Get < Command
      def run
        unless File.exist?(Config.data_path)
          raise "System info not yet gathered, try running 'collect' first" unless @options.force

          data = { primaryGroup: @options.primary,
                   secondaryGroups: @options.groups }
          data = data.deep_merge(Collector.physical_data)
          data = data.deep_merge(Collector.logical_data)
          File.open(Config.data_path, 'w') { |file| file.write(data.to_yaml) }
        end

        data = YAML.load_file(Config.data_path)
        keys = @args[0].delete_prefix(".").split(".")
        value = data
        keys.each do |key|
          if key.match(/\[[^\]]*\]/)
            key = key[1..-2]
            if key.to_i.to_s == key
              key = key.to_i
            end
          else
            key = key.to_sym
          end
          break if value.nil?
          value = value[key]
        end

        if value.respond_to?(:each)
          puts value.to_yaml
        else
          puts value
        end
      end
    end
  end
end
