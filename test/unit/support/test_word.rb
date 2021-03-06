# Copyright 2018 Noragh Analytics, Inc.
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
  include Armagh::Support::Word

  def setup
    @binary = StringIO.new('fake Word document')
    FakeFS { File.write('random.pdf', 'fake PDF document') }
    SecureRandom.stubs(:uuid).at_most(1).returns('random')
    Armagh::Support::Shell.stubs(:call).at_most(2).returns('pdf')
    self.stubs(:pdf_to_text).at_most(1).returns('text')
    self.stubs(:pdf_to_display).at_most(1).returns('display')
  end

  def test_word_to_text
    assert_equal 'text', FakeFS { word_to_text(@binary) }
  end

  def test_word_to_display
    assert_equal 'display', FakeFS { word_to_display(@binary) }
  end

  def test_word_to_text_and_display
    assert_equal ['text', 'display'], FakeFS { word_to_text_and_display(@binary) }
  end

  def test_word_to_text_no_text_content_error
    Armagh::Support::Shell.stubs(:call).raises(Armagh::Support::PDF::PDFNoTextError)
    self.stubs(:pdf_to_text).returns('')
    e = assert_raise WordNoTextError do
      FakeFS { word_to_text(@binary) }
    end
    assert_equal 'Unable to extract text from Word document', e.message
  end

end
