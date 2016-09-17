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

require_relative '../../../lib/armagh/support/excel'

class TestExcel < Test::Unit::TestCase

  def setup
    @binary   = StringIO.new('fake Excel document')
    out_file = 'random.html'
    html      = %Q(<p><table border="1">\n<caption>Sheet1</caption>\n<tr>\n<td colspan="2"  valign="bottom"  align="left"  style=" font-size:12pt;"><b>Worksheet 1 content</b></td>\n<td  style=""></td>\n</tr>\n<tr>\n<td colspan="33"  valign="bottom"  align="left"  style=" font-size:20pt;">We the People...</td>\n</tr>\n</table>\n<p><table border="1">\n<caption>Sheet2</caption>\n<tr>\n<td  valign="bottom"  align="left"  style=" font-size:12pt;">Worksheet 2 content</td>\n<td  style=""></td>\n</tr>\n<tr>\n<td  valign="bottom"  align="left"  style=" font-size:12pt;">Column1</td>\n<td  valign="bottom"  align="left"  style=" font-size:12pt;">Column2</td>\n<td  valign="bottom"  align="left"  style=" font-size:12pt;">Column3</td>\n<td  style=""></td>\n<td  style=""></td>\n<td  style=""></td>\n</tr>\n</table>)
    @text     = %Q(Sheet1\n\nWorksheet 1 content\n\nWe the People...\n\nSheet2\n\nWorksheet 2 content\n\nColumn1\nColumn2\nColumn3)
    @html     = %q(<p><b>Sheet1</b></p><table><tr><td colspan="2"  valign="bottom"  align="left">Worksheet 1 content</td><td></td></tr><tr><td colspan="33"  valign="bottom"  align="left">We the People...</td></tr></table></p><p><b>Sheet2</b></p><table><tr><td  valign="bottom"  align="left">Worksheet 2 content</td><td></td></tr><tr><td  valign="bottom"  align="left">Column1</td><td  valign="bottom"  align="left">Column2</td><td  valign="bottom"  align="left">Column3</td><td></td><td></td><td></td></tr></table></p>)

    FakeFS { File.write(out_file, html) }
    Armagh::Support::Shell.stubs(:call).at_most(1)
    SecureRandom.stubs(:uuid).at_most(1).returns('random')
  end

  def test_search_text
    assert_equal @text, FakeFS { Armagh::Support::Excel.to_search_text(@binary) }
  end

  def test_display_text
    assert_equal @html, FakeFS { Armagh::Support::Excel.to_display_text(@binary) }
  end

  def test_search_and_display_text
    assert_equal [@text, @html], FakeFS { Armagh::Support::Excel.to_search_and_display_text(@binary) }
  end

  def test_search_text_invalid_binary
    error = 'E Unsupported file format.'
    Armagh::Support::Shell.unstub(:call)
    Armagh::Support::Shell.stubs(:call).raises(Armagh::Support::Shell::ShellError, error)
    e = assert_raise Armagh::Support::Excel::ExcelError do
      Armagh::Support::Excel.to_search_text(nil)
    end
    assert_equal error, e.message
  end

  def test_private_class_method_process_excel
    e = assert_raise NoMethodError do
      Armagh::Support::Excel.process_excel(@binary, :search)
    end
    assert_equal "private method `process_excel' called for Armagh::Support::Excel:Module", e.message
  end

  def test_private_class_method_extract_text
    e = assert_raise NoMethodError do
      Armagh::Support::Excel.extract_text('anything', [:search])
    end
    assert_equal "private method `extract_text' called for Armagh::Support::Excel:Module", e.message
  end

end
