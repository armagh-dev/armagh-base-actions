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

  def test_call_error
    e = assert_raise Armagh::Support::Shell::ShellError do
      Armagh::Support::Shell.call('cmd_does_not_exist')
    end
    assert_equal 'Unable to execute "cmd_does_not_exist": No such file or directory - cmd_does_not_exist', e.message
  end

  def test_call_with_input
    assert_equal 'anything', Armagh::Support::Shell.call_with_input('cat', 'anything')
  end

  def test_call_with_input_missing_stdin
    e = assert_raise Armagh::Support::Shell::ShellError do
      Armagh::Support::Shell.call_with_input('cat')
    end
    assert_equal 'Unable to execute "cat": Missing standard input', e.message
  end

end
