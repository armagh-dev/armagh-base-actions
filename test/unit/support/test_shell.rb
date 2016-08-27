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


require_relative '../../helpers/coverage_helper'

require 'test/unit'

require_relative '../../../lib/armagh/support/shell'

class TestShell < Test::Unit::TestCase

  def test_call
    assert_equal Date.today.strftime('%Y%m%d'), Armagh::Support::Shell.call('date', '+%Y%m%d')
  end

  def test_call_missing_program
    e = assert_raise Armagh::Support::Shell::MissingProgramError do
      Armagh::Support::Shell.call('cmd_does_not_exist')
    end
    assert_equal 'Please install required program "cmd_does_not_exist"', e.message
  end

  def test_call_shell_error
    e = assert_raise Armagh::Support::Shell::ShellError do
      Armagh::Support::Shell.call('date', '-unknown')
    end
    assert_match %r(^Command "date -unknown" exited with error "date: \w+ option), e.message
  end

  def test_call_with_input
    assert_equal 'anything', Armagh::Support::Shell.call_with_input('cat', 'anything')
  end

  def test_call_with_input_missing_standard_input
    e = assert_raise Armagh::Support::Shell::ShellError do
      Armagh::Support::Shell.call_with_input('cat')
    end
    assert_equal 'Unable to execute "cat": Missing standard input', e.message
  end

  def test_call_timeout
    start = Time.now
    e = assert_raise Armagh::Support::Shell::TimeoutError do
      Armagh::Support::Shell.call('sleep 10', timeout: 0.01)
    end
    assert_in_delta 0.01, Time.now - start, 0.02
    assert_equal 'Execution expired "sleep 10"', e.message
  end

  def test_call_ignore_error
    assert_nothing_raised do
      Armagh::Support::Shell.call('date', '-unknown', ignore_error: 'option')
    end
  end

  def test_call_ignore_errors
    assert_nothing_raised do
      Armagh::Support::Shell.call('date', '-unknwon', ignore_error: ['not used', 'option'])
    end
  end

  def test_call_catch_error
    e = assert_raise Armagh::Support::Shell::ShellError do
      Armagh::Support::Shell.call('cat', '-unknown', ignore_error: 'cat', catch_error: 'option')
    end
    assert_match %r(^Command "cat -unknown" exited with error "cat: \w+ option), e.message
  end

  def test_call_catch_errors
    e = assert_raise Armagh::Support::Shell::ShellError do
      Armagh::Support::Shell.call('cat', '-unknown', ignore_error: ['not used', 'cat'],
                                                      catch_error: ['not used', 'option'])
    end
    assert_match %r(^Command "cat -unknown" exited with error "cat: \w+ option), e.message
  end

  def test_call_ignore_error_not_string
    assert_nothing_raised do
      Armagh::Support::Shell.call('cat', '-unknown', ignore_error: :option)
    end
  end

end
