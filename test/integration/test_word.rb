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

require_relative '../../lib/armagh/support/word'

class TestIntegrationWord < Test::Unit::TestCase
  include FixtureHelper

  def setup
    set_fixture_dir('word')
  end

  def test_to_search_text_doc
    binary = fixture('sample.doc')
    result = Armagh::Support::Word.to_search_text(binary)
    assert_equal fixture('sample.doc.search.txt', result), result
  end

  def test_to_display_text_doc
    binary = fixture('sample.doc')
    result = Armagh::Support::Word.to_display_text(binary)
    assert_equal fixture('sample.doc.display.txt', result), result
  end

  def test_to_search_and_display_text_doc
    binary = fixture('sample.doc')
    result = Armagh::Support::Word.to_search_and_display_text(binary)
    assert_equal [fixture('sample.doc.search.txt', result.first),
                  fixture('sample.doc.display.txt', result.last)], result
  end

  def test_to_search_text_docx
    binary = fixture('sample.docx')
    result = Armagh::Support::Word.to_search_text(binary)
    assert_equal fixture('sample.docx.search.txt', result), result
  end

  def test_to_display_text_docx
    binary = fixture('sample.docx')
    result = Armagh::Support::Word.to_display_text(binary)
    assert_equal fixture('sample.docx.display.txt', result), result
  end

  def test_to_search_and_display_text_docx
    binary = fixture('sample.docx')
    result = Armagh::Support::Word.to_search_and_display_text(binary)
    assert_equal [fixture('sample.docx.search.txt', result.first),
                  fixture('sample.docx.display.txt', result.last)], result
  end

  def test_to_search_text_docm
    binary = fixture('sample.docm')
    result = Armagh::Support::Word.to_search_text(binary)
    assert_equal fixture('sample.docm.search.txt', result), result
  end

  def test_to_display_text_docm
    binary = fixture('sample.docm')
    result = Armagh::Support::Word.to_display_text(binary)
    assert_equal fixture('sample.docm.display.txt', result), result
  end

  def test_to_search_and_display_text_docm
    binary = fixture('sample.docm')
    result = Armagh::Support::Word.to_search_and_display_text(binary)
    assert_equal [fixture('sample.docm.search.txt', result.first),
                  fixture('sample.docm.display.txt', result.last)], result
  end

  def test_to_search_text_invalid_document
    e = assert_raise Armagh::Support::Word::WordError do
      Armagh::Support::Word.to_search_text(StringIO.new('not a Word document'))
    end
    assert_match %r/Document is empty$/, e.message
  end

  def test_to_search_text_missing_program
    program = Armagh::Support::Word::WORD_TO_TEXT_SHELL[0]
    Armagh::Support::Word::WORD_TO_TEXT_SHELL[0] = 'missing_program'
    e = assert_raise Armagh::Support::Shell::MissingProgramError do
      Armagh::Support::Word.to_search_text(StringIO.new('fake Word document'))
    end
    assert_equal 'Please install required program "missing_program"', e.message
    Armagh::Support::Word::WORD_TO_TEXT_SHELL[0] = program
  end

end
