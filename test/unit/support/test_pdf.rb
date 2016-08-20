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
require 'fakefs/safe'
require 'mocha/test_unit'

require_relative '../../../lib/armagh/support/pdf'

class TestPDF < Test::Unit::TestCase

  def setup
    @binary = StringIO.new('fake pdf')
    FakeFS { File.open('file.pdf.txt', 'w') { |f| f << 'ocr text' } }
    SecureRandom.stubs(:uuid).returns('file')
  end

  def test_to_search_text
    Armagh::Support::Shell.stubs(:call).once.returns('called')
    assert_equal 'called', FakeFS { Armagh::Support::PDF.to_search_text(@binary) }
  end

  def test_display_text
    Armagh::Support::Shell.stubs(:call).once.returns('called')
    assert_equal 'called', FakeFS { Armagh::Support::PDF.to_display_text(@binary) }
  end

  def test_search_and_display_text
    Armagh::Support::Shell.stubs(:call).twice.returns('called')
    assert_equal ['called', 'called'],
      FakeFS { Armagh::Support::PDF.to_search_and_display_text(@binary) }
  end

  def test_ocr_no_text_content
    Armagh::Support::Shell.stubs(:call).twice.returns('')
    e = assert_raise Armagh::Support::PDF::NoTextError do
      FakeFS { Armagh::Support::PDF.to_search_text(@binary) }
    end
    assert_equal 'Unable to extract PDF text content', e.message
  end

  def test_ocr
    Armagh::Support::Shell.stubs(:call).times(4).returns('', 'Processing pages 1 through 1.')
    assert_equal 'ocr text', FakeFS { Armagh::Support::PDF.to_search_text(@binary) }
  end

  def test_timeout
    Armagh::Support::Shell.stubs(:call).once.then.raises(Armagh::Support::PDF::TimeoutError)
    assert_raise Armagh::Support::PDF::TimeoutError do
      FakeFS { Armagh::Support::PDF.to_search_text(@binary) }
    end
  end

  def test_private_class_method_process_pdf
    e = assert_raise NoMethodError do
      FakeFS { Armagh::Support::PDF.process_pdf(@binary, :search) }
    end
    assert_equal "private method `process_pdf' called for Armagh::Support::PDF:Module", e.message
  end

  def test_private_class_method_optical_character_recognition
    e = assert_raise NoMethodError do
      FakeFS { Armagh::Support::PDF.optical_character_recognition(@binary) }
    end
    assert_equal "private method `optical_character_recognition' called for Armagh::Support::PDF:Module", e.message
  end

end
