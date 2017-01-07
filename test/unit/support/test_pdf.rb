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


require_relative '../../helpers/coverage_helper'

require 'test/unit'
require 'fakefs/safe'
require 'mocha/test_unit'

require_relative '../../../lib/armagh/support/pdf'

class TestPDF < Test::Unit::TestCase
  include Armagh::Support::PDF

  def setup
    @binary = StringIO.new('fake PDF')
    FakeFS { File.write('file.pdf.txt', 'ocr text') }
    SecureRandom.stubs(:uuid).returns('file')
  end

  def test_pdf_to_text
    Armagh::Support::Shell.stubs(:call).once.returns('called')
    assert_equal 'called', FakeFS { pdf_to_text(@binary) }
  end

  def test_pdf_to_display
    Armagh::Support::Shell.stubs(:call).once.returns('called')
    assert_equal 'called', FakeFS { pdf_to_display(@binary) }
  end

  def test_pdf_to_text_and_display
    Armagh::Support::Shell.stubs(:call).twice.returns('called')
    assert_equal ['called', 'called'], FakeFS { pdf_to_text_and_display(@binary) }
  end

  def test_pdf_to_text_optical_character_recognition_no_text_content
    Armagh::Support::Shell.stubs(:call).twice.returns('')
    e = assert_raise PDFNoTextError do
      FakeFS { pdf_to_text(@binary) }
    end
    assert_equal 'Unable to extract PDF text content', e.message
  end

  def test_pdf_to_text_optical_character_recognition
    Armagh::Support::Shell.stubs(:call).times(4).returns('', 'Processing pages 1 through 1.')
    assert_equal 'ocr text', FakeFS { pdf_to_text(@binary) }
  end

  def test_pdf_to_text_timeout
    Armagh::Support::Shell.stubs(:call).once.then.raises(TimeoutError)
    assert_raise PDFTimeoutError do
      FakeFS { pdf_to_text(@binary) }
    end
  end

  def test_sanitize_bullets_points
    bullets = "\uf0b7\uf0a7\uf076\uf0d8\uf0fc\uf0a8\uf0de\uf0e0"
    Armagh::Support::Shell.stubs(:call).once.returns(bullets)
    assert_equal "\u2022" * bullets.size, FakeFS { pdf_to_text(@binary) }
  end

end
