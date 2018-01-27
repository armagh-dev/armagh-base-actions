# Copyright 2018 Noragh Analytics, Inc.
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

require 'configh'

module Armagh
  module Support
    module TimeParser
      include Configh::Configurable

      class TimeError           < StandardError; end
      class TypeMismatchError   < TimeError;     end
      class UnparsableTimeError < TimeError;     end
      class UnhandledError      < TimeError;     end

      define_parameter name:        'time_format',
                       description: "The time format used for parsing time if it can't be parsed natively by ruby's Time object",
                       type:        'string',
                       required:    false,
                       prompt:      "Time format should be formatted like the second argument to Time.strptime, e.g., '%m/%d/%Y'",
                       group:       'time_parser'

      module_function

      def parse_time(t, config)
        time_format = config.time_parser.time_format
        raise TypeMismatchError, "Argument passed to parse_time should be a String, instead: #{t.class}" unless t.is_a?(String)

        begin
          time = Time.parse(t)
        rescue ArgumentError => e
          if time_format
            time = parse_time_using_time_format(t, time_format)
          else
            raise
          end
        rescue ArgumentError => e
          raise UnparsableTimeError, "Unable to parse a time from the following argument passed to parse_time method: #{t.inspect}"
        rescue => e
          raise UnhandledError, "Unknown error raised when parsing time from the following argument: #{t.inspect}"
        end

        time
      end

      def parse_time_using_time_format(t, time_format)
        time_from_format = Time.strptime(t, time_format)
        time_derived_from_utc(time_from_format)
      rescue ArgumentError => e
        raise UnparsableTimeError, "Unable to parse a time (#{t.inspect}) from time format (#{time_format})"
      end

      def time_derived_from_utc(time)
        Time.utc(time.year,
                   time.mon,
                   time.day,
                   time.hour,
                   time.min,
                   time.sec)
      end

    end
  end
end
