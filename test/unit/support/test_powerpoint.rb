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

require_relative '../../../lib/armagh/support/powerpoint'

class TestPowerPoint < Test::Unit::TestCase

  def setup
    @binary = StringIO.new('fake PowerPoint document')
    FakeFS { File.write('random.pdf', 'fake PDF document') }
    SecureRandom.stubs(:uuid).at_most(1).returns('random')
    Armagh::Support::Shell.stubs(:call).at_most(2).returns('pdf')
    Armagh::Support::PDF.stubs(:to_search_text).at_most(1).returns('search')
    Armagh::Support::PDF.stubs(:to_display_text).at_most(1).returns('display')
  end

  def test_to_search_text
    assert_equal 'search', FakeFS { Armagh::Support::PowerPoint.to_search_text(@binary) }
  end

  def test_to_display_text
    assert_equal 'display', FakeFS { Armagh::Support::PowerPoint.to_display_text(@binary) }
  end

  def test_to_search_and_display_text
    assert_equal ['search',
                  'display'], FakeFS { Armagh::Support::PowerPoint.to_search_and_display_text(@binary) }
  end

  def test_private_class_method_process_powerpoint
    e = assert_raise NoMethodError do
      Armagh::Support::PowerPoint.process_powerpoint(@binary, :search)
    end
    assert_equal "private method `process_powerpoint' called for Armagh::Support::PowerPoint:Module", e.message
  end

end
