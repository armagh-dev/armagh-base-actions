# Copyright 2016 Noragh Analytics, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'parse-cron'

module Armagh
  module Support
    module Cron
      module_function

      class CronError < StandardError; end

      # Determines if a given string is valid cron syntax
      # @param cron_string [String] string representation of a cron
      # @return [Boolean] whether or not the string is a valid cron
      def valid_cron?(cron_string)
        valid = true
        begin
          CronParser.new(cron_string)
        rescue ArgumentError
          valid = false
        end
        valid
      end

      # Gets the next execution time of a given cron string.
      # @param cron_string [String] string representation of a cron
      # @param last_execution_time [Time] the time of the previous execution
      # @return [Time] the time of the next execution
      def next_execution_time(cron_string, last_execution_time = Time.now())
        parser = CronParser.new(cron_string)
        parser.next(last_execution_time)
      rescue
        raise CronError, 'An unexpected cron error occurred.'
      end
    end
  end
end
