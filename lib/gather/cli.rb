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
require_relative 'commands'
require_relative 'version'

require 'tty/reader'
require 'commander'

module Gather
  module CLI
    PROGRAM_NAME = ENV.fetch('FLIGHT_PROGRAM_NAME', 'gather')

    extend Commander::CLI
    program :application, 'Flight Gather'
    program :name, PROGRAM_NAME
    program :version, "v#{Gather::VERSION}"
    program :description, 'A tool to obtain relevant information about a node'
    program :help_paging, false
    default_command :help

    Paint.mode = 0 if [/^xterm/, /rxvt/, /256color/].all? { |regex| ENV['TERM'] !~ regex }

    class << self
      def cli_syntax(command, args_str = nil)
        command.syntax = [
          PROGRAM_NAME,
          command.name,
          args_str
        ].compact.join(' ')
      end
    end

    command :collect do |c|
      cli_syntax(c)
      c.summary = 'Gathers physical and/or logical system information'
      c.description = 'Gathers physical and/or logical system information'
      c.slop.string '--primary', 'Primary group for the node'
      c.slop.array '--groups', 'Comma-separated list of secondary groups for the node'
      c.slop.string '--type',
                    'Type of check to run (physical or logical), if not provided then both types are collected'
      c.action Commands, :collect
    end

    command :show do |c|
      cli_syntax(c)
      c.summary = 'Displays collected system information'
      c.description = 'Displays collected system information'
      c.slop.bool '--force', 'Gathers all information if not already gathered.'
      c.action Commands, :show
    end

    command :modify do |c|
      cli_syntax(c)
      c.summary = 'Reset primary and/or secondary group for the node'
      c.description = 'Reset primary and/or secondary group for the node'
      c.slop.string '--primary', 'Primary group for the node'
      c.slop.array '--groups', 'Comma-separated list of secondary groups for the node'
      c.action Commands, :modify
    end
  end
end
