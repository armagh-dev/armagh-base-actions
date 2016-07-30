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

require 'test/unit'

require_relative '../../lib/armagh/support/shell'
require_relative '../../lib/armagh/support/html'

class TestIntegrationHTML < Test::Unit::TestCase

  def setup
    @expected_web_chars = %q[' " & < > € ‚ ƒ „ … † ‡ ˆ ‰ Š ‹ œ Œ ‘ ’ “ ” • – — ∼ ˜ ™ š › Ÿ   ¡ ¢ £ ¤ ¥ ¦ § ¨ © ª « ¬ ­ ® ¯ ° ± ² ³ ´ µ ¶ · ¸ ¹ º » ¼ ½ ¾ ¿ À Á Â Ã Ä Å Æ Ç È É Ê Ë Ì Í Î Ï Ð Ñ Ò Ó Ô Õ Ö × Ø Ù Ú Û Ü Ý Þ ß à á â ã ä å æ ç è é ê ë ì í î ï ð ñ ò ó ô õ ö ÷ ø ù ú û ü ý þ ÿ]
  end

  def test_to_text
    set_program_path
    assert_equal "Just a normal sentence here.\n\nvérité është σε на očné của очевидец\n\nCopyright © 1999. Product™ ®",
      Armagh::Support::HTML.to_text(%q[
        <span>
          <div class="content">
            <p>Just a <i>normal</i> sentence <b>here</b>.</p>
          </div>
          <div class="special_characters">
            <p>vérité është σε на očné của очевидец</p>
          </div>
          <div class="footer">
            <p>Copyright © 1999. Product™ ®</p>
          </div>
        </span>
      ])
  end

  def test_to_text_missing_program
    set_program_path 'w3m_missing'
    e = assert_raise Armagh::Support::Shell::MissingProgramError do
      Armagh::Support::HTML.to_text('anything')
    end
    assert_equal 'Missing required w3m_missing program, please make sure it is installed', e.message
  end

  def test_to_text_web_chars
    set_program_path
    html = '&apos; &quot; &amp; &lt; &gt; &euro; &sbquo; &fnof; &bdquo; &hellip; &dagger; &Dagger; &circ; &permil; &Scaron; &lsaquo; &oelig; &OElig; &lsquo; &rsquo; &ldquo; &rdquo; &bull; &ndash; &mdash; &sim; &tilde; &trade; &scaron; &rsaquo; &Yuml; &nbsp; &iexcl; &cent; &pound; &curren; &yen; &brvbar; &sect; &uml; &copy; &ordf; &laquo; &not; &shy; &reg; &macr; &deg; &plusmn; &sup2; &sup3; &acute; &micro; &para; &middot; &cedil; &sup1; &ordm; &raquo; &frac14; &frac12; &frac34; &iquest; &Agrave; &Aacute; &Acirc; &Atilde; &Auml; &Aring; &AElig; &Ccedil; &Egrave; &Eacute; &Ecirc; &Euml; &Igrave; &Iacute; &Icirc; &Iuml; &ETH; &Ntilde; &Ograve; &Oacute; &Ocirc; &Otilde; &Ouml; &times; &Oslash; &Ugrave; &Uacute; &Ucirc; &Uuml; &Yacute; &THORN; &szlig; &agrave; &aacute; &acirc; &atilde; &auml; &aring; &aelig; &ccedil; &egrave; &eacute; &ecirc; &euml; &igrave; &iacute; &icirc; &iuml; &eth; &ntilde; &ograve; &oacute; &ocirc; &otilde; &ouml; &divide; &oslash; &ugrave; &uacute; &ucirc; &uuml; &yacute; &thorn; &yuml;'
    assert_equal @expected_web_chars, Armagh::Support::HTML.to_text(html)
  end

  def test_to_text_unicode_dec_chars
    set_program_path
    html = '&#39; &#34; &#38; &#60; &#62; &#8364; &#8218; &#402; &#8222; &#8230; &#8224; &#8225; &#710; &#8240; &#352; &#8249; &#339; &#338; &#8216; &#8217; &#8220; &#8221; &#8226; &#8211; &#8212; &#8764; &#732; &#8482; &#353; &#8250; &#376; &#160; &#161; &#162; &#163; &#164; &#165; &#166; &#167; &#168; &#169; &#170; &#171; &#172; &#173; &#174; &#175; &#176; &#177; &#178; &#179; &#180; &#181; &#182; &#183; &#184; &#185; &#186; &#187; &#188; &#189; &#190; &#191; &#192; &#193; &#194; &#195; &#196; &#197; &#198; &#199; &#200; &#201; &#202; &#203; &#204; &#205; &#206; &#207; &#208; &#209; &#210; &#211; &#212; &#213; &#214; &#215; &#216; &#217; &#218; &#219; &#220; &#221; &#222; &#223; &#224; &#225; &#226; &#227; &#228; &#229; &#230; &#231; &#232; &#233; &#234; &#235; &#236; &#237; &#238; &#239; &#240; &#241; &#242; &#243; &#244; &#245; &#246; &#247; &#248; &#249; &#250; &#251; &#252; &#253; &#254; &#255;'
    assert_equal @expected_web_chars, Armagh::Support::HTML.to_text(html)
  end

  def test_to_text_unicode_hex_chars
    set_program_path
    html = '&#x27; &#x22; &#x26; &#x3c; &#x3e; &#x20ac; &#x201a; &#x192; &#x201e; &#x2026; &#x2020; &#x2021; &#x2c6; &#x2030; &#x160; &#x2039; &#x153; &#x152; &#x2018; &#x2019; &#x201c; &#x201d; &#x2022; &#x2013; &#x2014; &#x223c; &#x2dc; &#x2122; &#x161; &#x203a; &#x178; &#xa0; &#xa1; &#xa2; &#xa3; &#xa4; &#xa5; &#xa6; &#xa7; &#xa8; &#xa9; &#xaa; &#xab; &#xac; &#xad; &#xae; &#xaf; &#xb0; &#xb1; &#xb2; &#xb3; &#xb4; &#xb5; &#xb6; &#xb7; &#xb8; &#xb9; &#xba; &#xbb; &#xbc; &#xbd; &#xbe; &#xbf; &#xc0; &#xc1; &#xc2; &#xc3; &#xc4; &#xc5; &#xc6; &#xc7; &#xc8; &#xc9; &#xca; &#xcb; &#xcc; &#xcd; &#xce; &#xcf; &#xd0; &#xd1; &#xd2; &#xd3; &#xd4; &#xd5; &#xd6; &#xd7; &#xd8; &#xd9; &#xda; &#xdb; &#xdc; &#xdd; &#xde; &#xdf; &#xe0; &#xe1; &#xe2; &#xe3; &#xe4; &#xe5; &#xe6; &#xe7; &#xe8; &#xe9; &#xea; &#xeb; &#xec; &#xed; &#xee; &#xef; &#xf0; &#xf1; &#xf2; &#xf3; &#xf4; &#xf5; &#xf6; &#xf7; &#xf8; &#xf9; &#xfa; &#xfb; &#xfc; &#xfd; &#xfe; &#xff;'
    assert_equal @expected_web_chars, Armagh::Support::HTML.to_text(html)
  end

  def test_to_text_sup
    set_program_path
    assert_equal '100th', Armagh::Support::HTML.to_text('100<sup>th</sup>')
  end

  def test_to_text_force_br
    set_program_path
    assert_equal "Item 1\nItem 2\nItem 3",
      Armagh::Support::HTML.to_text("Item 1\nItem 2\nItem 3", force_breaks: true)
  end

  private def set_program_path(program = 'w3m')
    shell = Armagh::Support::HTML::HTML_TO_TEXT_SHELL
    shell[0] = program
    Armagh::Support::HTML::HTML_TO_TEXT_SHELL.replace shell
  end

end