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

require_relative '../../lib/armagh/support/word'

class TestIntegrationWord < Test::Unit::TestCase
  include FixtureHelper
  include Armagh::Support::Word

  def setup
    set_fixture_dir('word')
  end

  def test_word_to_text_and_display_doc
    binary = fixture('sample.doc')
    result = word_to_text_and_display(binary)
    assert_equal [fixture('sample.doc.search.txt', result.first),
                  fixture('sample.doc.display.txt', result.last)], result
  end

  def test_word_to_text_and_display_docx
    binary = fixture('sample.docx')
    result = word_to_text_and_display(binary)
    assert_equal [fixture('sample.docx.search.txt', result.first),
                  fixture('sample.docx.display.txt', result.last)], result
  end

  def test_word_to_text_and_display_docm
    binary = fixture('sample.docm')
    result = word_to_text_and_display(binary)
    assert_equal [fixture('sample.docm.search.txt', result.first),
                  fixture('sample.docm.display.txt', result.last)], result
  end

  def test_word_to_text_invalid_document
    e = assert_raise WordError do
      word_to_text(StringIO.new('not a Word document'))
    end
    assert_match %r/Document is empty$/, e.message
  end

  def test_word_to_text_missing_program
    program = WORD_TO_TEXT_SHELL[0]
    WORD_TO_TEXT_SHELL[0] = 'missing_program'
    e = assert_raise Armagh::Support::Shell::MissingProgramError do
      word_to_text(StringIO.new('fake Word document'))
    end
    assert_equal 'Please install required program "missing_program"', e.message
    WORD_TO_TEXT_SHELL[0] = program
  end

end
