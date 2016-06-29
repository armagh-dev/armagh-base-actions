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

module Armagh
  module Actions
    module Loggable
      # Log a debug message.  Accepts either a block or a message
      # @yield Logs the given block
      # @param [String] msg logs a given message
      def log_debug(msg = nil)
        if block_given?
          @caller.log_debug(@logger_name) { yield }
        else
          @caller.log_debug(@logger_name, msg)
        end
      end

      # Log an info message.  Accepts either a block or a message
      # @yield Logs the given block
      # @param [String] msg logs a given message
      def log_info(msg = nil)
        if block_given?
          @caller.log_info(@logger_name) { yield }
        else
          @caller.log_info(@logger_name, msg)
        end
      end

      # Reports a given error as an operations error (fixed via things like configuration, service launching, etc)
      # @param [Object] error The error to report.  If the error is an exception, the exception will be reported, otherwise to_s is called.
      def notify_ops(error)
        @caller.notify_ops(@name, error)
      end

      # Reports a given error as a development error (Syntax error, not correctable w/out a code change, unexpected data format, etc)
      # @param [Object] error The error to report.  If the error is an exception, the exception will be reported, otherwise to_s is called.
      def notify_dev(error)
        @caller.notify_dev(@name, error)
      end
            
    end
  end
end
