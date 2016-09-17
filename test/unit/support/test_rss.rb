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
require 'webmock/test_unit'

require_relative '../../../lib/armagh/actions/collect'
require_relative '../../../lib/armagh/support/rss'

class TestRSS < Test::Unit::TestCase

  def setup
    @config_store = []
    @config = Armagh::Support::RSS.create_configuration( @config_store, 'rss', { 'http' => { 'url' => 'http://fake.url' },
                                                                                  'rss' => {
                                                                                    'additional_fields' => []
                                                                                  }})
  end

  def test_collect_bad_format
    stub_request(:get, 'http://fake.url').to_return(body: '')
    assert_raise(Armagh::Support::RSS::RSSParseError.new('Unable to parse RSS content from http://fake.url.  Poorly formatted feed.')){
      Armagh::Support::RSS.collect_rss(@config) { |item, content_str, timestamp, exception|}
    }
  end

  def test_collect_no_block
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'rss', { 'http' => { 'url' => 'http://fake.url' }, 'rss' => {}})
    assert_raise(ArgumentError){Armagh::Support::RSS.collect_rss(config)}
  end



end