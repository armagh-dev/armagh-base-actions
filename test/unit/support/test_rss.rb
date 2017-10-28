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
require 'mocha/test_unit'
require 'webmock/test_unit'

require_relative '../../../lib/armagh/support/rss'
require_relative '../../helpers/fixture_helper'
require_relative '../../../lib/armagh/actions/stateful'

class TestRSS < Test::Unit::TestCase
  include FixtureHelper

  def setup
    set_fixture_dir('rss')

    @config_store = []
    @config = Armagh::Support::RSS.create_configuration(@config_store, 'rss', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'additional_fields' => [], 'content_field' => 'description'}})

    @collection = mock
    @state_doc_id = '123'
    @pid = 'pid'
    @state = Armagh::Actions::ActionStateDocument.new(@collection, @state_doc_id, @pid)
  end

  def rss_test(filename, config_name, config = nil)
    content = fixture(filename)
    stub_request(:get, 'http://fake.url').to_return(body: content)

    @config = config || Armagh::Support::RSS.create_configuration(@config_store, config_name, {'http' => {'url' => 'http://fake.url'}, 'rss' => {'additional_fields' => [], 'content_field' => 'description'}})

    entered = false
    Armagh::Support::RSS.collect_rss(@config, @state) { |channel, item, content_array, type, timestamp, exception|
      entered = true
      assert_not_empty(channel)
      assert_not_empty(content_array)
      assert_equal([item['description'].gsub('&lt;div&gt;', '<div>')], content_array)
      assert_equal({'type' => 'text/html', 'encoding' => 'us-ascii'}, type)
      assert_kind_of(Time, timestamp)
      assert_nil exception
    }
    assert_true entered, 'RSS block never executed'
  end

  def test_collect_rss_0_91
    rss_test('rss-0.91.xml', 'rss-tcs091')
  end

  def test_collect_rss_0_92
    rss_test('rss-0.92.xml', 'rss-tcs092')
  end

  def test_collect_rss_2_0
    rss_test('rss-2.0.xml', 'rss-tcs20')
  end

  def test_collect_rss_invalid
    content = fixture('rss-no_description.xml')
    stub_request(:get, 'http://fake.url').to_return(body: content)

    config = Armagh::Support::RSS.create_configuration(@config_store, 'rss-tcri', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'additional_fields' => [], 'content_field' => 'description'}})

    entered = false
    Armagh::Support::RSS.collect_rss(config, @state) { |channel, item, content_array, type, timestamp, exception|
      entered = true
      assert_empty(content_array)
    }
    assert_true entered, 'RSS block never executed'
  end

  def test_collect_bad_format
    stub_request(:get, 'http://fake.url').to_return(body: 'gorp')
    assert_raise(Armagh::Support::RSS::RSSParseError.new('Unable to parse RSS content from http://fake.url.  Poorly formatted feed. Response body: gorp')) {
      Armagh::Support::RSS.collect_rss(@config, @state) { |channel, item, content_array, type, timestamp, exception|}
    }
  end

  def test_collect_no_block
    content = fixture('rss_link.xml')
    stub_request(:get, 'http://fake.url').to_return(body: content)
    config = Armagh::Support::HTTP.create_configuration(@config_store, 'rss', {'http' => {'url' => 'http://fake.url'}, 'rss' => {}})
    assert_raise(ArgumentError) { Armagh::Support::RSS.collect_rss(config, @state) }
  end

  def test_collect_link
    content = 'Some Content'

    stub_request(:get, 'http://fake.url').to_return(body: fixture('rss_link.xml'))
    stub_request(:get, 'http://another.fake.url').to_return(body: content, headers: {'Content-Type' => 'text/plain; charset=ISO-8859-1'})
    config = Armagh::Support::RSS.create_configuration(@config_store, 'rss_tcl', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'collect_link' => true}})
    entered = false
    Armagh::Support::RSS.collect_rss(config, @state) { |channel, item, content_array, type, timestamp, exception|
      entered = true
      assert_equal([content], content_array)
      assert_equal({'encoding' => 'ISO-8859-1', 'type' => 'text/plain'}, type)
    }
    assert_true entered, 'RSS block never executed'
  end

  def test_bad_link_collect
    stub_request(:get, 'http://fake.url').to_return(body: fixture('rss_link.xml'))
    stub_request(:get, 'http://another.fake.url').to_timeout
    config = Armagh::Support::RSS.create_configuration(@config_store, 'rss_tblc', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'collect_link' => true}})
    Armagh::Support::RSS.collect_rss(config, @state) { |channel, item, content_array, type, timestamp, exception|
      assert_kind_of(Armagh::Support::RSS::RSSError, exception)
    }
  end

  def test_collect_rss_with_html_escaped_links
    clean_link = "http://www2c.cdc.gov/podcasts/download.asp?af=h&f=8645217"
    Armagh::Support::HTTP::Connection.any_instance
      .expects(:fetch)
      .once
      .with(:multiple_pages => false)
      .returns(
        [ { "head"=>{"Status"=>"200", "Content-Type"=>"text/html; charset=us-ascii"}, "body" => fixture('rss_html_escaped_links.xml') } ]
      )
    Armagh::Support::HTTP::Connection.any_instance
      .expects(:fetch)
      .once
      .with(clean_link)
    config = Armagh::Support::RSS.create_configuration(@config_store, 'rss_tcl', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'collect_link' => true}})
    Armagh::Support::RSS.collect_rss(config, @state) { |channel, item, content_array, type, timestamp, exception|
    }
  end

  def test_collect_rss_with_link_pattern
    clean_link = "https://www.cdc.gov/salmonella/urbana-09-17/index.html"
    Armagh::Support::HTTP::Connection.any_instance
      .expects(:fetch)
      .once
      .with(:multiple_pages => false)
      .returns(
        [ { "head"=>{"Status"=>"200", "Content-Type"=>"text/html; charset=us-ascii"}, "body" => fixture('rss_source_url_links.xml') } ]
      )
    Armagh::Support::HTTP::Connection.any_instance
      .expects(:fetch)
      .once
      .with(clean_link)
    config = Armagh::Support::RSS.create_configuration(@config_store, 'rss_tcl', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'link_field' => 'link', 'collect_link' => true, 'link_pattern' => 'sourceurl=(.+?\.html)'}})
    Armagh::Support::RSS.collect_rss(config, @state) { |channel, item, content_array, type, timestamp, exception|
    }
  end

  def test_collect_rss_with_invalid_link_pattern
    item_link = 'https://tools.cdc.gov/api/embed/html/feedMetrics.html?channel=Outbreaks&language=eng&contenttitle=RSS+(h)%3a+Maradol+Papayas+-+Salmonella+Urbana&sourceurl=https%3a%2f%2fwww.cdc.gov%2fsalmonella%2furbana-09-17%2findex.html&c47=CDC+Outbreaks+-+US+Based&c8=RSS%3a+Click+Through'
    invalid_link_pattern = 'someurl=(.+?\.html)'
    Armagh::Support::HTTP::Connection.any_instance
      .expects(:fetch)
      .once
      .with(:multiple_pages => false)
      .returns(
        [ { "head"=>{"Status"=>"200", "Content-Type"=>"text/html; charset=us-ascii"}, "body" => fixture('rss_source_url_links.xml') } ]
      )
    config = Armagh::Support::RSS.create_configuration(@config_store, 'rss_tcl', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'link_field' => 'link', 'collect_link' => true, 'link_pattern' => invalid_link_pattern}})
    Armagh::Support::RSS.collect_rss(config, @state) { |channel, item, content_array, type, timestamp, exception|
      assert_kind_of(Armagh::Support::RSS::RSSLinkPatternError, exception)
    }
  end

  def test_description_no_content
    config = Armagh::Support::RSS.create_configuration(@config_store, 'rss-tdnc092', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'additional_fields' => [], 'description_no_content' => true}})
    rss_test('rss-0.92.xml', 'rss-tdnc092', config)
  end

  def test_max_items
    stub_request(:get, 'http://fake.url').to_return(body: fixture('rss-0.92.xml'))
    num_items = 3
    config = Armagh::Support::RSS.create_configuration(@config_store, 'rss_tmi', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'additional_fields' => [], 'max_items' => num_items}})
    count = 0
    Armagh::Support::RSS.collect_rss(config, @state) { |channel, item, content_array, type, timestamp, exception|
      count += 1
    }
    assert_equal(num_items, count)
  end

  def test_media_type
    content = fixture('rss_media_type.xml')
    sub_content = 'something'
    stub_request(:get, 'http://fake.url').to_return(body: content)
    stub_request(:get, 'http://another.fake.url').to_return(body: sub_content)
    config = Armagh::Support::RSS.create_configuration(@config_store, 'rss-tmt', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'collect_link' => true}})

    entered = false
    Armagh::Support::RSS.collect_rss(config, @state) { |channel, item, content_array, type, timestamp, exception|
      entered = true
      assert_equal([sub_content], content_array)
      assert_equal({'type' => 'pdf', 'encoding' => 'binary'}, type)
    }
    assert_true entered, 'RSS block never executed'
  end

  def test_already_collected
    content = fixture('rss_times.xml')
    stub_request(:get, 'http://fake.url').to_return(body: content)
    @state.content['last_collect'] = Time.new(2000, 01, 01)

    items = []
    Armagh::Support::RSS.collect_rss(@config, @state) { |channel, item, content_array, type, timestamp, exception|
      items << item
    }

    assert_equal 1, items.length
    assert_equal 'New Item', items.first['description']
  end


  def test_full_collect
    content = fixture('rss_times.xml')
    stub_request(:get, 'http://fake.url').to_return(body: content)
    @state.content['last_collect'] = Time.new(2000, 01, 01)
    config = Armagh::Support::RSS.create_configuration(@config_store, 'rss-tfc', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'full_collect' => true}})

    items = []
    Armagh::Support::RSS.collect_rss(config, @state) { |channel, item, content_array, type, timestamp, exception|
      items << item
    }

    assert_equal 2, items.length
    descriptions = items.collect{|i| i['description']}.sort
    assert_equal(['New Item', 'Old Item'], descriptions)
  end

  def test_collect_complex_path
    content = fixture('rss_media_type.xml')
    stub_request(:get, 'http://fake.url').to_return(body: content)
    config = Armagh::Support::RSS.create_configuration(@config_store, 'rss_tccp', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'content_field' => 'media:content type', 'link_field' => 'something fake'}})

    expected = ['pdf']
    actual = nil
    Armagh::Support::RSS.collect_rss(config, @state) { |channel, item, content_array, type, timestamp, exception|
      actual = content_array
    }
    assert_equal(expected, actual)


    config = Armagh::Support::RSS.create_configuration(@config_store, 'rss-tccp', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'content_field' => 'media:content#type', 'link_field' => 'something fake'}})
    actual = nil
    Armagh::Support::RSS.collect_rss(config, @state) { |channel, item, content_array, type, timestamp, exception|
      actual = content_array
    }
    assert_equal(expected, actual)
  end

  def test_multiple_collect_not_first
    content = 'Some Content'

    stub_request(:get, 'http://fake.url').to_return(body: fixture('rss_link.xml'))
    stub_request(:get, 'http://another.fake.url').to_return(body: content, headers: {'Content-Type' => 'text/plain; charset=ISO-8859-1'})
    config = Armagh::Support::RSS.create_configuration(@config_store, 'rss_tcl', {'http' => {'url' => 'http://fake.url'}, 'rss' => {'collect_link' => true}})
    entered = false

    Armagh::Support::HTTP.expects(:get_next_page_url).with(content, 'http://fake.url', 'http://another.fake.url').never
    Armagh::Support::HTTP.expects(:get_next_page_url).with(content, 'http://another.fake.url/', 'http://another.fake.url/')

    Armagh::Support::RSS.collect_rss(config, @state) { |channel, item, content_array, type, timestamp, exception|
      entered = true
      assert_equal([content], content_array)
      assert_equal({'encoding' => 'ISO-8859-1', 'type' => 'text/plain'}, type)
    }
    assert_true entered, 'RSS block never executed'
  end
end
