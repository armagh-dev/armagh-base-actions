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

require 'timeout'

module Armagh
  module Support
    module Shell
      module_function

      class ShellError          < StandardError; end
      class MissingProgramError < ShellError; end
      class TimeoutError        < ShellError; end

      DEFAULT_TIMEOUT = 60

      def call(*args, timeout: nil, ignore_error: nil, catch_error: nil)
        call_shell(*args, input: nil, timeout: timeout, ignore_error: ignore_error, catch_error: catch_error)
      end

      def call_with_input(*args, input, timeout: nil, ignore_error: nil, catch_error: nil)
        call_shell(*args, input: input, timeout: timeout, ignore_error: ignore_error, catch_error: catch_error)
      end

      private_class_method def call_shell(*args, input:, timeout:, ignore_error:, catch_error:)
        if args.empty?
          command = input
          raise %Q(Unable to execute "#{command}": Missing standard input)
        end

        command   = parse_args(args)

        timeout ||= DEFAULT_TIMEOUT
        pid       = nil
        stdout    = stderr = status = ''

        in_read,  in_write  = IO.pipe; in_write.sync = true
        out_read, out_write = IO.pipe
        err_read, err_write = IO.pipe

        opts = {in: in_read, out: out_write, err: err_write, pgroup: true}

        Timeout.timeout(timeout) do
          pid = spawn(command, opts)
          wait = Process.detach(pid)

          in_read.close
          out_write.close
          err_write.close

          stdout = Thread.new { out_read.read }
          stderr = Thread.new { err_read.read }

          in_write.write(input) if input
          in_write.close

          status = wait.value
        end

        unless status.success? && stderr&.value&.empty?
          error = stderr&.value&.empty? ? 'Process was not successful' : stderr.value
          handle_error(error, command, ignore_error, catch_error)
        end
      rescue Errno::ENOENT => e
        if e.message.include?('No such file or directory - ' + args.first)
          raise MissingProgramError, 'Please install required program ' + args.first.inspect
        else
          handle_error(e, command, ignore_error, catch_error)
        end
      rescue Timeout::Error => e
        Process.kill('TERM', -pid)
        handle_error(e, command, ignore_error, catch_error)
      rescue => e
        handle_error(e, command, ignore_error, catch_error)
      else
        stdout.value.strip
      ensure
        out_read.close if out_read && !out_read.closed?
        err_read.close if err_read && !err_read.closed?
      end

      private_class_method def parse_args(args)
        args.flatten!
        args.collect! { |arg| arg.to_s.strip.empty? ? "''" : arg }
        args.join(' ')
      end

      private_class_method def handle_error(error, command, ignore_error = nil, catch_error = nil)
        if error.is_a?(Exception)
          if error.class == Timeout::Error
            raise TimeoutError, %Q(Execution expired "#{command}")
          else
            raise ShellError, error
          end
        else
          error_caught = false
          Array(catch_error).each do |e|
            if error.to_s.include?(e.to_s)
              error_caught = true
              break
            end
          end
          Array(ignore_error).each { |e| return if error.to_s.include?(e.to_s) } unless error_caught

          raise ShellError, %Q(Command "#{command}" exited with error "#{error.strip}")
        end
      end

    end
  end
end
