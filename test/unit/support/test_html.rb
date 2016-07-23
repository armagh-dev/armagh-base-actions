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
require 'mocha/test_unit'

require_relative '../../../lib/armagh/support/shell'
require_relative '../../../lib/armagh/support/html'

class TestHTML < Test::Unit::TestCase

  def setup
    Armagh::Support::Shell.stubs(:call_with_input).at_most(1).returns('called')
  end

  def test_to_text
    assert_equal 'called', Armagh::Support::HTML.to_text('test')
  end

  def test_to_text_mismatch
    e = assert_raise Armagh::Support::HTML::MismatchError do
      Armagh::Support::HTML.to_text(nil)
    end
    assert_equal 'HTML must be a String, instead: NilClass', e.message
  end

end
