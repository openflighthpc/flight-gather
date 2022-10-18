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

def between(string, s1, s2) # Returns the contents of string between the last instance of s1 and the next subsequent instance of s2
  if string.include? s1 and string.split(s1).last.include? s2
    string.split(s1).last.split(s2).first
  else ""
  end
end
