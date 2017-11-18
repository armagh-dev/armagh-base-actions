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
require_relative '../helpers/mongo_support'

require 'test/unit'

require_relative '../../lib/armagh/support/rss'
require_relative '../../lib/armagh/actions/stateful'

class TestIntegrationRSS < Test::Unit::TestCase

  def self.startup
    MongoSupport.instance.start_mongo
  end

  def self.shutdown
    MongoSupport.instance.stop_mongo
  end

  def setup
    MongoSupport.instance.clean_database
    @action_state_store = MongoSupport.instance.client['test_action_state_store']

    config_values_from_file = load_local_integration_test_config
    @feed_url = File.join(config_values_from_file['test_http_url'], 'rss_feed.rss')

    @config_values = {
      'http' => {
        'url' => @feed_url,
      },
      'rss' => {
        'full_collect' => true,
        'collect_link' => true
      }
    }

    @config_store = []

    @config = Armagh::Support::RSS.create_configuration(@config_store, 'abc', @config_values)
    @action_state_doc = {}
  end

  def load_local_integration_test_config
    config = nil
    config_filepath = File.join(__dir__, 'local_integration_test_config.json')

    begin
      config = JSON.load(File.read(config_filepath))
      errors = []
      if config.is_a? Hash
        %w(test_http_url).each do |k|
          errors << "Config file missing member #{k}" unless config.has_key?(k)
        end
      else
        errors << 'Config file should contain a hash of test_http_url'
      end

      raise errors.join("\n") unless errors.empty?
    rescue => e
      pend "Integration test environment not set up.  See test/integration/ftp_test.readme.  Detail: #{ e.message }"
    end
    config
  end

  def test_rss_collect
    item_count = 1

    base_date = Time.utc(1964, 7, 30, 8, 15)

    Armagh::Support::RSS.collect_rss(@config, @action_state_doc) do |channel, item, content_str, type, timestamp, exception|
      item_date = base_date + item_count*86400
      assert_equal('RSS Test', channel['title'])
      assert_equal('The Fickle Finger of Fate', channel['author'])
      assert_equal('Secrets of the Universe', channel['description'])
      assert_equal(@feed_url, channel['link'])
      assert_equal('en', channel['language'])

      assert_equal("Item #{item_count}", item['title'])
      assert_true item['link'].end_with? "?item_id=#{item_count}"
      assert_equal('FFF', item['author'])
      assert_equal("The description text for item #{item_count}", item['description'])
      assert_equal(item_date, item['pubDate'])
      assert_equal("ITEM-GUID-#{item_count}", item['guid'])
      assert_equal(item_date, item['armagh_timestamp'])

      assert_equal(["<!DOCTYPE html>\n<html>\n<head>\n  <title>TestWebServer</title>\n</head>\n<body>\n\n<h1>This is "\
          "RSS item #{item_count}.</h1>\n<p>There really isn't much more to say.</p>\n\n</body>\n</html>\n"], content_str)

      assert_equal({'type' => 'text/html', 'encoding' => 'utf-8'}, type)

      assert_equal(item_date, timestamp)

      assert_nil exception

      item_count += 1
    end
  end

  def test_rss_collect_history
    config_values = {
      'http' => {
        'url' => @feed_url,
      },
      'rss' => {
        'max_items' => 1
      }
    }

    config = Armagh::Support::RSS.create_configuration(@config_store, 'collect_1', config_values)
    items = []

    3.times do
      Armagh::Support::RSS.collect_rss(config, @action_state_doc) do |channel, item, content_str, type, timestamp, exception|
        items << item
      end
    end

    items.collect!{|i| i['guid']}.compact!
    assert_equal(%w(ITEM-GUID-1 ITEM-GUID-2 ITEM-GUID-3), items)
  end
end
