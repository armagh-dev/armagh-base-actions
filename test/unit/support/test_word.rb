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
require 'fakefs/safe'

require_relative '../../../lib/armagh/support/word'

class TestWord < Test::Unit::TestCase

  def setup
    @binary = StringIO.new('fake Word document')
    FakeFS { File.write('random.pdf', 'fake PDF document') }
    Armagh::Support::Shell.stubs(:call).at_most(3).returns(nil, 'success')
    SecureRandom.stubs(:uuid).at_most(3).returns('random')
  end

  def test_to_search_text
    assert_equal 'success', FakeFS { Armagh::Support::Word.to_search_text(@binary) }
  end

  def test_to_display_text
    assert_equal 'success', FakeFS { Armagh::Support::Word.to_display_text(@binary) }
  end

  def test_to_search_and_display_text
    assert_equal ['success', 'success'], FakeFS { Armagh::Support::Word.to_search_and_display_text(@binary) }
  end

end
