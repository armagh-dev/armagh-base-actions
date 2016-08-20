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

      DEFAULT_TIMEOUT = 60

      class ShellError          < StandardError; end
      class MissingProgramError < ShellError; end
      class TimeoutError        < ShellError; end

      def call(*args, timeout: DEFAULT_TIMEOUT, ignore_error: nil)
        call_shell(*args, timeout: timeout, ignore_error: ignore_error)
      end

      def call_with_input(*args, input, timeout: DEFAULT_TIMEOUT, ignore_error: nil)
        call_shell(*args, input: input, timeout: timeout, ignore_error: ignore_error)
      end

      private_class_method def call_shell(*args, input: nil, timeout: DEFAULT_TIMEOUT, ignore_error: nil)
        if args.empty?
          command = input
          raise ShellError, 'Missing standard input'
        end

        command = parse_args(args)

        pid = nil
        stdout = stderr = status = ''
        in_read, in_write   = IO.pipe
        out_read, out_write = IO.pipe
        err_read, err_write = IO.pipe
        in_write.sync = true

        opts = {
          in: in_read,
          out: out_write,
          err: err_write,
          pgroup: true
        }

        Timeout.timeout(timeout) do
          pid = spawn(command, opts)
          wait = Process.detach(pid)

          in_read.close
          out_write.close
          err_write.close

          stdout = Thread.new { out_read.read }
          stderr = Thread.new { err_read.read }

          in_write.write input if input
          in_write.close

          status = wait.value
        end

        if stderr && !stderr.value.empty?
          handle_error(stderr.value, command, ignore_error)
        elsif !status.success?
          handle_error("Process was not successful: #{status.inspect}", command, ignore_error)
        end
      rescue Timeout::Error => e
        Process.kill('TERM', -pid)
        handle_error(e, command, ignore_error)
      rescue => e
        handle_error(e, command, ignore_error)
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

      private_class_method def handle_error(error, command, ignore_error = nil)
        if error.is_a? Exception
          raise TimeoutError, %Q(Execution expired "#{command}") if error.class == Timeout::Error
          raise ShellError, %Q(Unable to execute "#{command}": #{error.message})
        else
          return if ignore_error && error.include?(ignore_error)
          raise ShellError, %Q(Shell command "#{command}" exited with error: #{error})
        end
      end

    end
  end
end
