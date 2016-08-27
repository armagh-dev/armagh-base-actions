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


require_relative '../helpers/coverage_helper'
require_relative '../helpers/fixture'

require 'test/unit'

require_relative '../../lib/armagh/support/excel'

class TestIntegrationExcel < Test::Unit::TestCase
  include FixtureHelper

  def setup
    set_fixture_dir('excel')
  end

  def test_to_search_text_xls
    binary = fixture('sample.xls')
    result = Armagh::Support::Excel.to_search_text(binary)
    assert_equal fixture('sample.xls.search.txt', result), result
  end

  def test_to_display_text_xls
    binary = fixture('sample.xls')
    result = Armagh::Support::Excel.to_display_text(binary)
    assert_equal fixture('sample.xls.display.txt', result), result
  end

  def test_to_search_and_display_text_xls
    binary = fixture('sample.xls')
    result = Armagh::Support::Excel.to_search_and_display_text(binary)
    assert_equal [fixture('sample.xls.search.txt', result.first),
                  fixture('sample.xls.display.txt', result.last)], result
  end

  def test_to_search_text_xlsx
    binary = fixture('sample.xlsx')
    result = Armagh::Support::Excel.to_search_text(binary)
    assert_equal fixture('sample.xlsx.search.txt', result), result
  end

  def test_to_display_text_xlsx
    binary = fixture('sample.xlsx')
    result = Armagh::Support::Excel.to_display_text(binary)
    assert_equal fixture('sample.xlsx.display.txt', result), result
  end

  def test_to_search_and_display_text_xlsx
    binary = fixture('sample.xlsx')
    result = Armagh::Support::Excel.to_search_and_display_text(binary)
    assert_equal [fixture('sample.xlsx.search.txt', result.first),
                  fixture('sample.xlsx.display.txt', result.last)], result
  end

  def test_to_search_text_xlsm
    binary = fixture('sample.xlsm')
    result = Armagh::Support::Excel.to_search_text(binary)
    assert_equal fixture('sample.xlsm.search.txt', result), result
  end

  def test_to_display_text_xlsm
    binary = fixture('sample.xlsm')
    result = Armagh::Support::Excel.to_display_text(binary)
    assert_equal fixture('sample.xlsm.display.txt', result), result
  end

  def test_to_search_and_display_text_xlsm
    binary = fixture('sample.xlsm')
    result = Armagh::Support::Excel.to_search_and_display_text(binary)
    assert_equal [fixture('sample.xlsm.search.txt', result.first),
                  fixture('sample.xlsm.display.txt', result.last)], result
  end

  def test_to_search_text_invalid_document
    e = assert_raise Armagh::Support::Excel::ExcelError do
      Armagh::Support::Excel.to_search_text(nil)
    end
    assert_match %r(E Unsupported file format\.), e.message
  end

  def test_to_search_text_missing_program
    program = Armagh::Support::Excel::EXCEL_TO_TEXT_SHELL[0]
    Armagh::Support::Excel::EXCEL_TO_TEXT_SHELL[0] = 'missing_program'
    e = assert_raise Armagh::Support::Shell::MissingProgramError do
      Armagh::Support::Excel.to_search_text(StringIO.new('fake Excel document'))
    end
    assert_equal 'Please install required program "missing_program"', e.message
    Armagh::Support::Excel::EXCEL_TO_TEXT_SHELL[0] = program
  end

end
