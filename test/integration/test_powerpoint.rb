# Copyright 2017 Noragh Analytics, Inc.
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


require_relative '../helpers/coverage_helper'
require_relative '../helpers/fixture_helper'

require 'test/unit'

require_relative '../../lib/armagh/support/powerpoint'

class TestIntegrationPowerPoint < Test::Unit::TestCase
  include FixtureHelper
  include Armagh::Support::PowerPoint

  def setup
    set_fixture_dir('powerpoint')
  end

  def test_powerpoint_to_text_and_display_ppt
    binary = fixture('sample.ppt')
    result = powerpoint_to_text_and_display(binary)
    assert_equal [fixture('sample.ppt.search.txt', result.first),
                  fixture('sample.ppt.display.txt', result.last)], result
  end

  def test_powerpoint_to_text_and_display_pptx
    binary = fixture('sample.pptx')
    result = powerpoint_to_text_and_display(binary)
    assert_equal [fixture('sample.pptx.search.txt', result.first),
                  fixture('sample.pptx.display.txt', result.last)], result
  end

  def test_powerpoint_to_text_and_display_pptm
    binary = fixture('sample.pptm')
    result = powerpoint_to_text_and_display(binary)
    assert_equal [fixture('sample.pptm.search.txt', result.first),
                  fixture('sample.pptm.display.txt', result.last)], result
  end

  def test_powerpoint_to_text_invalid_document
    e = assert_raise Armagh::Support::PowerPoint::PowerPointError do
      powerpoint_to_text(StringIO.new('not a PowerPoint document'))
    end
    assert_match %r/Document is empty$/, e.message
  end

  def test_to_search_text_missing_program
    program = POWERPOINT_TO_PDF_SHELL[0]
    POWERPOINT_TO_PDF_SHELL[0] = 'missing_program'
    e = assert_raise Armagh::Support::Shell::MissingProgramError do
      powerpoint_to_text(StringIO.new('fake PowerPoint document'))
    end
    assert_equal 'Please install required program "missing_program"', e.message
    POWERPOINT_TO_PDF_SHELL[0] = program
  end

end
