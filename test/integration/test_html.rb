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

require_relative '../../lib/armagh/support/html'

class TestIntegrationHTML < Test::Unit::TestCase
  include FixtureHelper
  include Armagh::Support::HTML

  def setup
    # Note: The space in the following variable is a UTF-8 NO BREAK SPACE. (NOT ASCII space)
    # See: http://www.utf8-chartable.de/unicode-utf8-table.pl?utf8=dec
    @expected_web_chars = %q[' " & < > € ‚ ƒ „ … † ‡ ˆ ‰ Š ‹ œ Œ ‘ ’ “ ” • – — ∼ ˜ ™ š › Ÿ   ¡ ¢ £ ¤ ¥ ¦ § ¨ © ª « ¬ ® ¯ ° ± ² ³ ´ µ ¶ · ¸ ¹ º » ¼ ½ ¾ ¿ À Á Â Ã Ä Å Æ Ç È É Ê Ë Ì Í Î Ï Ð Ñ Ò Ó Ô Õ Ö × Ø Ù Ú Û Ü Ý Þ ß à á â ã ä å æ ç è é ê ë ì í î ï ð ñ ò ó ô õ ö ÷ ø ù ú û ü ý þ ÿ]
    @config = Armagh::Support::HTML.create_configuration([], 'html', {})
    set_fixture_dir('html')
  end

  def test_html_to_text
    assert_equal "Just a normal sentence here.\n\nvérité është σε на očné của очевидец\n\nCopyright © 1999. Product™ ®",
      html_to_text(%q[
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
      ], @config)
  end

  def test_html_to_text_multiple_html_parts
    config = Armagh::Support::HTML.create_configuration([], 'roll_call', 'html'=>{
      'extract_after'=>'<div.*?>',
      'extract_until'=>'</div>',
      'exclude'=>[
        '<span.*?</span>']})
    html     = 'header<div><span>ignore</span>&apos;html<![CDATA[ignore]]><sup>&apos;</sup></div>footer'
    title    = '&apos;title<![CDATA[<!-- comment -->]]>&apos;'
    source   = '&apos;source&apos;'
    empty    = ''
    result   = html_to_text(html, title, source, empty, config)
    expected = ["'html'", "'title'", "'source'", '']
    assert_equal expected, result
  end

  def test_html_to_text_missing_program
    constant = Armagh::Support::HTML::HTML_TO_TEXT_SHELL
    restore = constant.first
    constant[0] = 'w3m_missing'
    constant.replace(constant)

    e = assert_raise Armagh::Support::HTML::HTMLError do
      html_to_text('anything', @config)
    end
    assert_equal 'Please install required program "w3m_missing"', e.message

    constant[0] = restore
    constant.replace(constant)
  end

  def test_html_to_text_web_chars
    # Note: The space in the following variable is an ASCII space.
-   expected_web_chars = %q[' " & < > € ‚ ƒ „ … † ‡ ˆ ‰ Š ‹ œ Œ ‘ ’ “ ” • – — ∼ ˜ ™ š › Ÿ   ¡ ¢ £ ¤ ¥ ¦ § ¨ © ª « ¬ ® ¯ ° ± ² ³ ´ µ ¶ · ¸ ¹ º » ¼ ½ ¾ ¿ À Á Â Ã Ä Å Æ Ç È É Ê Ë Ì Í Î Ï Ð Ñ Ò Ó Ô Õ Ö × Ø Ù Ú Û Ü Ý Þ ß à á â ã ä å æ ç è é ê ë ì í î ï ð ñ ò ó ô õ ö ÷ ø ù ú û ü ý þ ÿ]
    html = '&apos; &quot; &amp; &lt; &gt; &euro; &sbquo; &fnof; &bdquo; &hellip; &dagger; &Dagger; &circ; &permil; &Scaron; &lsaquo; &oelig; &OElig; &lsquo; &rsquo; &ldquo; &rdquo; &bull; &ndash; &mdash; &sim; &tilde; &trade; &scaron; &rsaquo; &Yuml; &nbsp; &iexcl; &cent; &pound; &curren; &yen; &brvbar; &sect; &uml; &copy; &ordf; &laquo; &not; &reg; &macr; &deg; &plusmn; &sup2; &sup3; &acute; &micro; &para; &middot; &cedil; &sup1; &ordm; &raquo; &frac14; &frac12; &frac34; &iquest; &Agrave; &Aacute; &Acirc; &Atilde; &Auml; &Aring; &AElig; &Ccedil; &Egrave; &Eacute; &Ecirc; &Euml; &Igrave; &Iacute; &Icirc; &Iuml; &ETH; &Ntilde; &Ograve; &Oacute; &Ocirc; &Otilde; &Ouml; &times; &Oslash; &Ugrave; &Uacute; &Ucirc; &Uuml; &Yacute; &THORN; &szlig; &agrave; &aacute; &acirc; &atilde; &auml; &aring; &aelig; &ccedil; &egrave; &eacute; &ecirc; &euml; &igrave; &iacute; &icirc; &iuml; &eth; &ntilde; &ograve; &oacute; &ocirc; &otilde; &ouml; &divide; &oslash; &ugrave; &uacute; &ucirc; &uuml; &yacute; &thorn; &yuml;'
    assert_equal expected_web_chars, html_to_text(html, @config)
  end

  def test_html_to_text_unicode_dec_chars
    config = Armagh::Support::HTML.create_configuration([], 'unicode', 'html' => { 'unescape_html' => true })
    html = '&#39; &#34; &#38; &#60; &#62; &#8364; &#8218; &#402; &#8222; &#8230; &#8224; &#8225; &#710; &#8240; &#352; &#8249; &#339; &#338; &#8216; &#8217; &#8220; &#8221; &#8226; &#8211; &#8212; &#8764; &#732; &#8482; &#353; &#8250; &#376; &#160; &#161; &#162; &#163; &#164; &#165; &#166; &#167; &#168; &#169; &#170; &#171; &#172; &#174; &#175; &#176; &#177; &#178; &#179; &#180; &#181; &#182; &#183; &#184; &#185; &#186; &#187; &#188; &#189; &#190; &#191; &#192; &#193; &#194; &#195; &#196; &#197; &#198; &#199; &#200; &#201; &#202; &#203; &#204; &#205; &#206; &#207; &#208; &#209; &#210; &#211; &#212; &#213; &#214; &#215; &#216; &#217; &#218; &#219; &#220; &#221; &#222; &#223; &#224; &#225; &#226; &#227; &#228; &#229; &#230; &#231; &#232; &#233; &#234; &#235; &#236; &#237; &#238; &#239; &#240; &#241; &#242; &#243; &#244; &#245; &#246; &#247; &#248; &#249; &#250; &#251; &#252; &#253; &#254; &#255;'
    assert_equal @expected_web_chars, html_to_text(html, config)
  end

  def test_html_to_text_unicode_hex_chars
    config = Armagh::Support::HTML.create_configuration([], 'unicode', 'html' => { 'unescape_html' => true })
    html = '&#x27; &#x22; &#x26; &#x3c; &#x3e; &#x20ac; &#x201a; &#x192; &#x201e; &#x2026; &#x2020; &#x2021; &#x2c6; &#x2030; &#x160; &#x2039; &#x153; &#x152; &#x2018; &#x2019; &#x201c; &#x201d; &#x2022; &#x2013; &#x2014; &#x223c; &#x2dc; &#x2122; &#x161; &#x203a; &#x178; &#xa0; &#xa1; &#xa2; &#xa3; &#xa4; &#xa5; &#xa6; &#xa7; &#xa8; &#xa9; &#xaa; &#xab; &#xac; &#xae; &#xaf; &#xb0; &#xb1; &#xb2; &#xb3; &#xb4; &#xb5; &#xb6; &#xb7; &#xb8; &#xb9; &#xba; &#xbb; &#xbc; &#xbd; &#xbe; &#xbf; &#xc0; &#xc1; &#xc2; &#xc3; &#xc4; &#xc5; &#xc6; &#xc7; &#xc8; &#xc9; &#xca; &#xcb; &#xcc; &#xcd; &#xce; &#xcf; &#xd0; &#xd1; &#xd2; &#xd3; &#xd4; &#xd5; &#xd6; &#xd7; &#xd8; &#xd9; &#xda; &#xdb; &#xdc; &#xdd; &#xde; &#xdf; &#xe0; &#xe1; &#xe2; &#xe3; &#xe4; &#xe5; &#xe6; &#xe7; &#xe8; &#xe9; &#xea; &#xeb; &#xec; &#xed; &#xee; &#xef; &#xf0; &#xf1; &#xf2; &#xf3; &#xf4; &#xf5; &#xf6; &#xf7; &#xf8; &#xf9; &#xfa; &#xfb; &#xfc; &#xfd; &#xfe; &#xff;'
    assert_equal @expected_web_chars, html_to_text(html, config)
  end

  def test_politico
    config = Armagh::Support::HTML.create_configuration([], 'politico', 'html'=>{
      'extract_after'=>'<div class="story-text.*?">',
      'extract_until'=>'<div class="story-supplement.*?">',
      'exclude'=>[
        '<aside.*?</aside>',
        '<div.*?</div>',
        '<style.*?</style>',
        '<footer.*?</footer>']})
    html = fixture('politico.html')
    text = html_to_text(html, config)
    assert_equal fixture('politico.html.txt', text), text
  end

  def test_reuters
    config = Armagh::Support::HTML.create_configuration([], 'reuters', 'html'=>{
      'extract_after'=>'<span id="article-text">',
      'extract_until'=>'<div class="linebreak"></div>',
      'exclude'=>[
        '<div.*?</div>']})
    html = fixture('reuters.html')
    text = html_to_text(html, config)
    assert_equal fixture('reuters.html.txt', text), text
  end

  def test_roll_call
    config = Armagh::Support::HTML.create_configuration([], 'roll_call', 'html'=>{
      'extract_after'=>'<div id="mainbody_content" class="clearfix.*?">',
      'extract_until'=>'<div class="sharinginfo"',
      'exclude'=>[
        '<div.*?</div>',
        '<figure.*?</figure>']})
    html = fixture('roll_call.html')
    text = html_to_text(html, config)
    assert_equal fixture('roll_call.html.txt', text), text
  end

  def test_the_hill
    config = Armagh::Support::HTML.create_configuration([], 'the_hill', 'html'=>{
      'extract_after'=>'<article.*?>',
      'extract_until'=>'<div class="article-tags',
      'exclude'=>[
        '<div class="clearfix.*?</div>',
        '<div class="credits.*?</div>',
        '<div class="share.*?</div>',
        '<div id=".*?</div>',
        '<header.*?</header>',
        '<img.*?>',
        '<p class="submitted.*?</p>',
        '<span>ADVERTISEMENT</span>']})
    html = fixture('the_hill.html')
    text = html_to_text(html, config)
    assert_equal fixture('the_hill.html.txt', text), text
  end

  def test_cdc_travel_notice
    config = Armagh::Support::HTML.create_configuration([], 'cdc_travel_notice', 'html'=>{
      'extract_after'=>'<div id="body.*?>',
      'extract_until'=>'<footer id="footer">',
      'exclude'=>[
        '<div class="disabled.*?</div>']})
    html = fixture('cdc_travel_notice.html')
    text = html_to_text(html, config)
    assert_equal fixture('cdc_travel_notice.html.txt', text), text
  end

  def test_cyber_kendra
    config = Armagh::Support::HTML.create_configuration([], 'cyber_kendra', 'html'=>{
      'extract_after'=>'<div class="post-body.*?>',
      'extract_until'=>'<div class="post-footer.*?>',
      'exclude'=>[
        '<div class="separator".*?</div>']})
    html = fixture('cyber_kendra.html')
    text = html_to_text(html, config)
    assert_equal fixture('cyber_kendra.html.txt', text), text
  end

  def test_cyber_security
    config = Armagh::Support::HTML.create_configuration([], 'cyber_security', 'html'=>{
      'extract_after'=>'<div id="main-content.*?>',
      'extract_until'=>'<div id="sidebar',
      'exclude'=>[
        '<div class="region.*?</div>',
        '<h2 class="title.*?</h2>',
        '<p class="author.*?</p>',
        '<div class="published-text.*?</div>',
        '<div class="subtilte-summary.*?</div>',
        '<div class="image-container.*?</div>',
        '<span class="aaauthor.*?</span>',
        '<div class="links.*?</div>',
        '<div id="links.*?</div>',
        '<div id="more-stories.*?</div>']})
    html = fixture('cyber_security.html')
    text = html_to_text(html, config)
    assert_equal fixture('cyber_security.html.txt', text), text
  end

  def test_cylance
    config = Armagh::Support::HTML.create_configuration([], 'cylance', 'html'=>{
      'extract_after'=>'<div class="section post-body.*?>',
      'extract_until'=>'<p id="hubspot-topic_data.*?>',
      'exclude'=>[
        '<img.*?>']})
    html = fixture('cylance.html')
    text = html_to_text(html, config)
    assert_equal fixture('cylance.html.txt', text), text
  end

  def test_e_hacking_news
    config = Armagh::Support::HTML.create_configuration([], 'e_hacking_news', 'html'=>{
      'extract_after'=>'<div dir="ltr.*?>',
      'extract_until'=>'<div id="entry-tags',
      'exclude'=>[
        '<div class="separator.*?</div>',
        '<a class="twitter-follow-button.*?</a>']})
    html = fixture('e_hacking_news.html')
    text = html_to_text(html, config)
    assert_equal fixture('e_hacking_news.html.txt', text), text
  end

  def test_fire_eye
    config = Armagh::Support::HTML.create_configuration([], 'fire_eye', 'html'=>{
      'extract_after'=>'<div class="entrytext section.*?>',
      'extract_until'=>'<div class="metadata',
      'exclude'=>[
        '<img.*?>',
        '<style.*?</style>']})
    html = fixture('fire_eye.html')
    text = html_to_text(html, config)
    assert_equal fixture('fire_eye.html.txt', text), text
  end

  def test_nss_labs
    config = Armagh::Support::HTML.create_configuration([], 'nss_labs', 'html'=>{
      'extract_after'=>'<section id="content-part.*?>',
      'extract_until'=>'<span class="tags',
      'exclude'=>[
        '<h1.*?</h1>',
        '<ul class="blogMeta.*?</ul>',
        '<img.*?>']})
    html = fixture('nss_labs.html')
    text = html_to_text(html, config)
    assert_equal fixture('nss_labs.html.txt', text), text
  end

  def test_sc_magazine
    config = Armagh::Support::HTML.create_configuration([], 'sc_magazine', 'html'=>{
      'extract_after'=>'<article.*?>',
      'extract_until'=>'</article>',
      'exclude'=>[
        '<span class="articleDate.*?</span>',
        '<h1 class="articleHeadline.*?</h1>',
        '<p class="articleHeadQuote.*?</p>',
        '<script.*?</script>',
        '<div class="contentSocialBar.*?</div>']})
    html = fixture('sc_magazine.html')
    text = html_to_text(html, config)
    assert_equal fixture('sc_magazine.html.txt', text), text
  end

  def test_seculert
    config = Armagh::Support::HTML.create_configuration([], 'seculert', 'html'=>{
      'extract_after'=>'<div class="an-item-blog.*?>',
      'extract_until'=>'<p class="an-link-social',
      'exclude'=>[
        '<h3.*?</h3>',
        '<div class="an-group-link.*?</div>',
        '<img.*?>']})
    html = fixture('seculert.html')
    text = html_to_text(html, config)
    assert_equal fixture('seculert.html.txt', text), text
  end

  def test_security_affairs
    config = Armagh::Support::HTML.create_configuration([], 'security_affairs', 'html'=>{
      'extract_after'=>'<div class="post_inner_wrapper.*?>',
      'extract_until'=>'<div class="ssba',
      'exclude'=>[
        '<g:plusone.*?</g:plusone>',
        '<h2.*?</h2>',
        '<div class="fcbk_share.*?</div>',
        '<img.*?>']})
    html = fixture('security_affairs.html')
    text = html_to_text(html, config)
    assert_equal fixture('security_affairs.html.txt', text), text
  end

  def test_state_dept_travel_alert
    config = Armagh::Support::HTML.create_configuration([], 'state_dept_travel_alert', 'html'=>{
      'extract_after'=>'<div class="parsys content_par.*?>',
      'extract_until'=>'<div class="high country-map-rail'})
    html = fixture('state_dept_travel_alert.html')
    text = html_to_text(html, config)
    assert_equal fixture('state_dept_travel_alert.html.txt', text), text
  end

  def test_comtex
    config = Armagh::Support::HTML.create_configuration([], 'comtex', 'html' => {
      'extract_after' => '<div class="body">',
      'extract_until' => '<div class="copyright">',
      'unescape_html' => true,
      'preserve_hyperlinks' => true
    })
    html = fixture('comtex.html')
    title = 'G20 &lt;matched_term&gt;Summit&lt;/matched_term&gt;: Donald Trump pitches for free and &lt;matched_term&gt;fair&lt;/matched_term&gt; trade'
    source   = '&apos;source&apos;'
    text = html_to_text(html, title, source, config)
    text[0].strip!
    exp_text = fixture('comtex.html.txt', text)
    exp_title = 'G20 Summit: Donald Trump pitches for free and fair trade'
    expected_results = %W(#{exp_text} #{exp_title} 'source')
    assert_equal expected_results, text
  end
end
