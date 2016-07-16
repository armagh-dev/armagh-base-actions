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

require 'open3'

module Armagh
  module Support
    module Shell
      module_function

      class ShellError          < StandardError; end
      class MissingProgramError < ShellError; end

      def call(*args)
        command = parse_args(args)
        stdout, stderr, _status = Open3.capture3(command)
        handle_error(stderr, command) unless stderr.empty?
      rescue => e
        handle_error(e, command)
      else
        stdout.strip
      end

      def call_with_input(*args, input)
        unless args.any?
          command = input
          raise ShellError, 'Missing standard input (must be the last argument)'
        end
        command = parse_args(args)
        stdout, stderr, _status = Open3.capture3(command, stdin_data: input)
        handle_error(stderr, command) unless stderr.empty?
      rescue => e
        handle_error(e, command)
      else
        stdout.strip
      end

      private def parse_args(args)
        args.flatten!
        # TODO test empty argument, e.g., "echo 'test' | grep ''"
        args.collect! { |arg| arg.to_s.strip.empty? ? "''" : arg }
        args.join(' ')
      end

      private def handle_error(error, command)
        if error.is_a? Exception
          raise ShellError, %Q[Unable to execute "#{command}": #{error.message}]
        else
          raise ShellError, %Q[Shell command "#{command}" exited with error: #{error}]
        end
      end
    end
  end
end
