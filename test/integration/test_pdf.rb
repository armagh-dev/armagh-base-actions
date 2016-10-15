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
require_relative '../helpers/fixture_helper'

require 'test/unit'

require_relative '../../lib/armagh/support/pdf'

class TestIntegrationPDF < Test::Unit::TestCase
  include FixtureHelper

  def setup
    set_fixture_dir('pdf')
  end

  def test_to_search_text
    binary = fixture('sample.pdf')
    result = Armagh::Support::PDF.to_search_text(binary)
    assert_equal fixture('sample.pdf.search.txt', result), result
  end

  def test_to_display_text
    binary = fixture('sample.pdf')
    result = Armagh::Support::PDF.to_display_text(binary)
    assert_equal fixture('sample.pdf.display.txt', result), result
  end

  def test_to_search_text_ocr
    binary = fixture('rotated.pdf')
    result = Armagh::Support::PDF.to_search_text(binary)
    assert_equal fixture('rotated.pdf.search.txt', result), result
  end

  def test_to_search_text_table
    binary = fixture('table.pdf')
    result = Armagh::Support::PDF.to_search_text(binary)
    assert_equal fixture('table.pdf.search.txt', result), result
  end

  def test_to_search_and_display_text
    binary = fixture('datatables_sampleall.pdf')
    result = Armagh::Support::PDF.to_search_and_display_text(binary)
    assert_equal [fixture('datatables_sampleall.pdf.search.txt', result.first),
                  fixture('datatables_sampleall.pdf.display.txt', result.last)], result
  end

  def test_to_search_and_display_text_timeout
    start = Time.now
    binary = fixture('rotated.pdf')
    e = assert_raise Armagh::Support::PDF::TimeoutError do
      Armagh::Support::PDF.to_search_and_display_text(binary, timeout: 1)
    end
    assert_equal 'Execution expired while processing PDF', e.message
    assert_in_delta 1, Time.now - start, 0.5
  end

  def test_to_search_text_invalid_document
    binary = fixture('sample.pdf.search.txt')
    e = assert_raise Armagh::Support::PDF::PDFError do
      Armagh::Support::PDF.to_search_text(binary)
    end
    assert_match %r/May not be a PDF file/, e.message
  end

  def test_to_search_text_missing_program
    program = Armagh::Support::PDF::PDF_TO_TEXT_SHELL[0]
    Armagh::Support::PDF::PDF_TO_TEXT_SHELL[0] = 'missing_program'
    e = assert_raise Armagh::Support::Shell::MissingProgramError do
      Armagh::Support::PDF.to_search_text(StringIO.new('fake PDF document'))
    end
    assert_equal 'Please install required program "missing_program"', e.message
    Armagh::Support::PDF::PDF_TO_TEXT_SHELL[0] = program
  end

end
