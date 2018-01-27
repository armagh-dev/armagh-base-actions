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

require_relative '../../../lib/armagh/support/html'

class TestHTML < Test::Unit::TestCase
  include Armagh::Support::HTML

  def setup
    @html   = %Q(<html><head><title>test</title></head><body style="font-family: Arial;"><p>text</p>\n<![CDATA[cdata]]></body></html>)
    @config = Armagh::Support::HTML.create_configuration([], 'html', {})
    Armagh::Support::Shell.stubs(:call_with_input).with { |_, html| @result = html }.once.returns('called')
  end

  def test_html_to_text_multiple_html_parts
    html   = '&apos;html<![CDATA[ignore]]><sup>&apos;</sup>'
    title  = '&apos;title<![CDATA[<!-- comment -->]]>&apos;'
    source = '&apos;source&apos;'
    html_to_text(html, title, source, @config)
    expected = %w('html' 'title' 'source')
    assert_equal expected, @result.split(HTML_PART_DELIMITER)
  end

  def test_html_to_text_default_params
    assert_equal 'called', html_to_text(@html, @config)
    expected = @html.sub(/<!\[CDATA.*?>/, '')
    assert_equal expected, @result
  end

  def test_html_to_text_param_extract_after
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html'=>{
      'extract_after'=>'<body.*?>'})
    html_to_text(@html, config)
    expected = @html[/<body.*?>(.*)$/m, 1]
    expected.sub!(/<!\[CDATA.*?>/, '')
    assert_equal expected, @result
  end

  def test_html_to_text_param_extract_until
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html'=>{
      'extract_until'=>'<body'})
    html_to_text(@html, config)
    expected = @html[/^(.*?)<body/m, 1]
    assert_equal expected, @result
  end

  def test_html_to_text_param_extract_body
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html'=>{
      'extract_after'=>'<body.*?>',
      'extract_until'=>'</body>'})
    html_to_text(@html, config)
    expected = @html[/<body.*?>(.*?)<\/body>/m, 1]
    expected.sub!(/<!\[CDATA.*?>/, '')
    assert_equal expected, @result
  end

  def test_html_to_text_param_exclude
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html'=>{
      'exclude'=>[
        '<![CDATA[.*?]]>',
        'test']})
    html_to_text(@html, config)
    expected = @html.sub(/<!\[CDATA.*?\]\]>/, '')
    expected.sub!(/test/, '')
    assert_equal expected, @result
  end

  def test_html_to_text_param_ignore_cdata_true
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html'=>{
      'ignore_cdata'=>true})
    html_to_text(@html, config)
    expected = @html.sub(/<!\[CDATA.*?\]\]>/, '')
    assert_equal expected, @result
  end

  def test_html_to_text_param_ignore_cdata_false
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html'=>{
      'ignore_cdata'=>false})
    html_to_text(@html, config)
    expected = @html.gsub(/<!\[CDATA\[|\]\]>/, '')
    assert_equal expected, @result
  end

  def test_html_to_text_extract_cdata
    config = Armagh::Support::HTML.create_configuration([], 'nested_cdata', 'html'=>{
      'ignore_cdata'=>false})
    html = 'one <![CDATA[two]]> three <![CDATA[four]]> five'
    html_to_text(html, config)
    assert_equal 'one two three four five', @result
  end

  def test_html_to_text_extract_nested_cdata
    config = Armagh::Support::HTML.create_configuration([], 'nested_cdata', 'html'=>{
      'ignore_cdata'=>false})
    html = 'nested1=<![CDATA[cdata1+]]]]><![CDATA[>cdata2]]> nested2=<![CDATA[cdata1+]]]><![CDATA[]>cdata2]]>'
    html_to_text(html, config)
    assert_equal 'nested1=cdata1+cdata2 nested2=cdata1+cdata2', @result
  end

  def test_html_to_text_param_force_breaks
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html'=>{
      'force_breaks'=>true})
    html_to_text(@html, config)
    assert_match %r/<br \\>/, @result
  end

  def test_html_to_text_replace_apos_with_single_quote
    html_to_text('&apos;quote&apos;', @config)
    assert_equal "'quote'", @result
  end

  def test_html_to_text_strip_sup_tag
    html_to_text('100<sup>th</sup>', @config)
    assert_equal '100th', @result
  end

  def test_html_to_text_invalid_html
    Armagh::Support::Shell.unstub(:call_with_input)
    e = assert_raise InvalidHTMLError do
      html_to_text(nil, nil)
    end
    assert_equal 'HTML must be a String, instead: NilClass', e.message
  end

  def test_html_to_text_empty_html
    html_to_text('', @config)
    assert_equal '', @result
  end

  def test_html_to_text_with_empty_array_elements
    html_to_text('', 'one', '', 'two', '', @config)
    assert_equal ['', 'one', '', 'two', ''], @result.split(HTML_PART_DELIMITER, 5)
  end

  def test_html_to_text_invalid_config
    Armagh::Support::Shell.unstub(:call_with_input)
    e = assert_raise HTMLError do
      html_to_text('html', nil)
    end
    assert_equal "undefined method `html' for nil:NilClass", e.message
  end

  def test_html_to_text_unescape_html
    html = '<p>HSBC(&lt;a href="http://www.marketintelligencecenter.com/symbol/HSBC"&gt;HSBC&lt;/a&gt;)</p>'
    expected_results = '<p>HSBC(<a href="http://www.marketintelligencecenter.com/symbol/HSBC">HSBC</a>)</p>'
    html_to_text(html, @config)
    assert_equal html, @result
    Armagh::Support::Shell.stubs(:call_with_input).with { |_, html| @result = html }.once.returns('called')
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html' => {'unescape_html' => true})
    html_to_text(html, config)
    assert_equal expected_results, @result
  end

  def test_html_to_text_unescape_html_url_params
    html = '<a href="https://some.website.com/url.php?docid=http%3A%2F%2Fwww.business.com%2Farticle%2Fpti-stories%2Fmalaysia.html&amp;dbid=1108&amp;title=Malaysia&amp;pubdate=2017-06-22+07%3A18%3A00&amp;datasource=src&amp;referrer=api">click here</a>'
    expected_results = '<a href="https://some.website.com/url.php?docid=http%3A%2F%2Fwww.business.com%2Farticle%2Fpti-stories%2Fmalaysia.html&dbid=1108&title=Malaysia&pubdate=2017-06-22+07%3A18%3A00&datasource=src&referrer=api">click here</a>'
    html_to_text(html, @config)
    assert_equal html, @result
    Armagh::Support::Shell.stubs(:call_with_input).with { |_, html| @result = html }.once.returns('called')
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html' => {'unescape_html' => true})
    html_to_text(html, config)
    assert_equal expected_results, @result
  end

  def test_html_to_text_preserve_hyperlinks_with_no_target_blank
    html = '<a href="https://some.website.com/url.php?docid=http%3A%2F%2Fwww.business.com%2Farticle%2Fpti-stories%2Fmalaysia.html&amp;dbid=1108&amp;title=Malaysia&amp;pubdate=2017-06-22+07%3A18%3A00&amp;datasource=src&amp;referrer=api">click here</a>'
    expected_results = "click here [ https://some.website.com/url.php?docid=http%3A%2F%2Fwww.business.com%2Farticle%2Fpti-stories%2Fmalaysia.html&dbid=1108&title=Malaysia&pubdate=2017-06-22+07%3A18%3A00&datasource=src&referrer=api ]"
    html_to_text(html, @config)
    assert_equal html, @result
    Armagh::Support::Shell.stubs(:call_with_input).with { |_, html| @result = html }.once.returns('called')
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html' => {
      'unescape_html' => true,
      'preserve_hyperlinks' => true
    })
    html_to_text(html, config)
    assert_equal expected_results, @result
  end

  def test_html_to_text_preserve_hyperlinks_with_target_blank
    html = '<a target="_blank" href="https://some.website.com/url.php?docid=http%3A%2F%2Fwww.business.com%2Farticle%2Fpti-stories%2Fmalaysia.html&amp;dbid=1108&amp;title=Malaysia&amp;pubdate=2017-06-22+07%3A18%3A00&amp;datasource=src&amp;referrer=api">click here</a>'
    expected_results = "click here [ https://some.website.com/url.php?docid=http%3A%2F%2Fwww.business.com%2Farticle%2Fpti-stories%2Fmalaysia.html&amp;dbid=1108&amp;title=Malaysia&amp;pubdate=2017-06-22+07%3A18%3A00&amp;datasource=src&amp;referrer=api ]"
    html_to_text(html, @config)
    assert_equal html, @result
    Armagh::Support::Shell.stubs(:call_with_input).with { |_, html| @result = html }.once.returns('called')
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html' => {'preserve_hyperlinks' => true})
    html_to_text(html, config)
    assert_equal expected_results, @result
  end

  def test_html_to_text_preserve_hyperlinks_with_target_blank_mixed_case
    html = '<a target="_BlAnK" href="https://some.website.com/url.php?docid=http%3A%2F%2Fwww.business.com%2Farticle%2Fpti-stories%2Fmalaysia.html&amp;dbid=1108&amp;title=Malaysia&amp;pubdate=2017-06-22+07%3A18%3A00&amp;datasource=src&amp;referrer=api">click here</a>'
    expected_results = "click here [ https://some.website.com/url.php?docid=http%3A%2F%2Fwww.business.com%2Farticle%2Fpti-stories%2Fmalaysia.html&amp;dbid=1108&amp;title=Malaysia&amp;pubdate=2017-06-22+07%3A18%3A00&amp;datasource=src&amp;referrer=api ]"
    html_to_text(html, @config)
    assert_equal html, @result
    Armagh::Support::Shell.stubs(:call_with_input).with { |_, html| @result = html }.once.returns('called')
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html' => {'preserve_hyperlinks' => true})
    html_to_text(html, config)
    assert_equal expected_results, @result
  end

  def test_html_to_text_preserve_hyperlinks_with_target_blank_single_quotes
    html = "<a target='_blank' href=\"https://some.website.com/url.php?docid=http%3A%2F%2Fwww.business.com%2Farticle%2Fpti-stories%2Fmalaysia.html&amp;dbid=1108&amp;title=Malaysia&amp;pubdate=2017-06-22+07%3A18%3A00&amp;datasource=src&amp;referrer=api\">click here</a>"
    expected_results = "click here [ https://some.website.com/url.php?docid=http%3A%2F%2Fwww.business.com%2Farticle%2Fpti-stories%2Fmalaysia.html&amp;dbid=1108&amp;title=Malaysia&amp;pubdate=2017-06-22+07%3A18%3A00&amp;datasource=src&amp;referrer=api ]"
    html_to_text(html, @config)
    assert_equal html, @result
    Armagh::Support::Shell.stubs(:call_with_input).with { |_, html| @result = html }.once.returns('called')
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html' => {'preserve_hyperlinks' => true})
    html_to_text(html, config)
    assert_equal expected_results, @result
  end

  def test_html_to_text_preserve_hyperlinks_with_target_not_blank
    html = '<a target="GrossePointeBlank" href="https://some.website.com/url.php?docid=http%3A%2F%2Fwww.business.com%2Farticle%2Fpti-stories%2Fmalaysia.html&amp;dbid=1108&amp;title=Malaysia&amp;pubdate=2017-06-22+07%3A18%3A00&amp;datasource=src&amp;referrer=api">click here</a>'
    expected_results = "click here [ https://some.website.com/url.php?docid=http%3A%2F%2Fwww.business.com%2Farticle%2Fpti-stories%2Fmalaysia.html&amp;dbid=1108&amp;title=Malaysia&amp;pubdate=2017-06-22+07%3A18%3A00&amp;datasource=src&amp;referrer=api ]"
    html_to_text(html, @config)
    assert_equal html, @result
    Armagh::Support::Shell.stubs(:call_with_input).with { |_, html| @result = html }.once.returns('called')
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html' => {'preserve_hyperlinks' => true})
    html_to_text(html, config)
    assert_equal expected_results, @result
  end

  def test_html_to_text_preserve_hyperlinks_with_url_in_label
    html = '<a href="https://www.globenewswire.com/Tracker?data=EFRRVphfpv_p_jHzGFY-kHkFWTumkQaMimvXzB-JcIQpMgAGnsCuqyzM05TyVU5mH_d0XGuQ08xhn9OFCrX9cvIXAeF98KCPjM5HNjAHOdA=" rel="nofollow" target="_blank">www.apachecorp.com</a>'
    expected_results = "www.apachecorp.com [ https://www.globenewswire.com/Tracker?data=EFRRVphfpv_p_jHzGFY-kHkFWTumkQaMimvXzB-JcIQpMgAGnsCuqyzM05TyVU5mH_d0XGuQ08xhn9OFCrX9cvIXAeF98KCPjM5HNjAHOdA= ]"
    html_to_text(html, @config)
    assert_equal html, @result
    Armagh::Support::Shell.stubs(:call_with_input).with { |_, html| @result = html }.once.returns('called')
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html' => {'preserve_hyperlinks' => true})
    html_to_text(html, config)
    assert_equal expected_results, @result
  end

  def test_html_to_text_preserve_hyperlinks_with_no_anchors
    html = '<p>To view the table and graph associated with this release, please click on the following link: http://media3.marketwire.com/docs/1098744.pdf&#160;</p>'
    html_to_text(html, @config)
    assert_equal html, @result
    Armagh::Support::Shell.stubs(:call_with_input).with { |_, html| @result = html }.once.returns('called')
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html' => {'preserve_hyperlinks' => true})
    html_to_text(html, config)
    assert_equal html, @result
  end

  def test_html_to_text_preserve_hyperlinks_with_same_link_and_label
    html = '<a href="http://www.google.com">http://www.google.com</a>'
    expected_results = "http://www.google.com"
    html_to_text(html, @config)
    assert_equal html, @result
    Armagh::Support::Shell.stubs(:call_with_input).with { |_, html| @result = html }.once.returns('called')
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html' => {'preserve_hyperlinks' => true})
    html_to_text(html, config)
    assert_equal expected_results, @result
  end

  def test_html_to_text_preserve_hyperlinks_with_multiple_named_anchors_in_same_line
    html = '<a href="https://link-one">label one</a> <a href="https://link-two">label two</a>'
    expected_results = "label one [ https://link-one ] label two [ https://link-two ]"
    html_to_text(html, @config)
    assert_equal html, @result
    Armagh::Support::Shell.stubs(:call_with_input).with { |_, html| @result = html }.once.returns('called')
    config = Armagh::Support::HTML.create_configuration([], 'html', 'html' => {'preserve_hyperlinks' => true})
    html_to_text(html, config)
    assert_equal expected_results, @result
  end

  def test_merge_multiple_pages
    Armagh::Support::Shell.unstub(:call_with_input)
    merged = Armagh::Support::HTML.merge_multiple_pages(%w(ONE TWO THREE FOUR))
    assert_equal("ONE\n\n--- PAGE 2 ---\n\nTWO\n\n--- PAGE 3 ---\n\nTHREE\n\n--- PAGE 4 ---\n\nFOUR", merged)
  end

end
