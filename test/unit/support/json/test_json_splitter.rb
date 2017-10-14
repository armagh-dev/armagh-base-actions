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

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../helpers/fixture_helper'
require_relative '../../../helpers/coverage_helper'
require_relative '../../../../lib/armagh/support/json/splitter'

class TestJSONSplitter < Test::Unit::TestCase

  include FixtureHelper

  def setup
    set_fixture_dir('json')
    @config = Armagh::Support::JSON::Splitter.create_configuration([], 'json', 'json_splitter'=>{'split_target'=>'employees'})
  end

  def test_split_with_valid_json
    json = fixture('test.json')
    small_jsons = Armagh::Support::JSON::Splitter.split_parts(json, @config)

    expected_jsons = fixture('expected_output/expected_split_content.txt', small_jsons.to_s)
    assert_equal expected_jsons, small_jsons.to_s
  end

  def test_split_with_json_of_invalid_type
    json = [1, 2, 3]
    e = assert_raise Armagh::Support::JSON::Splitter::JSONTypeError do
      Armagh::Support::JSON::Splitter.split_parts(json, @config)
    end
    assert_equal 'JSON must be a string', e.message
  end

  def test_split_with_empty_json_string
    json = ''
    e = assert_raise Armagh::Support::JSON::Splitter::JSONValueError do
      Armagh::Support::JSON::Splitter.split_parts(json, @config)
    end
    assert_equal 'JSON cannot be nil or empty', e.message
  end

  def test_split_with_nil_json_string
    json = nil
    e = assert_raise Armagh::Support::JSON::Splitter::JSONTypeError do
      Armagh::Support::JSON::Splitter.split_parts(json, @config)
    end
    assert_equal 'JSON must be a string', e.message
  end

  def test_split_with_malformed_json_string
    json = '{ "company": "Example, Inc.",'
    e = assert_raise Armagh::Support::JSON::Splitter::JSONParseError do
      Armagh::Support::JSON::Splitter.split_parts(json, @config)
    end
    assert_match (/Unable to parse JSON string passed to JSONSplitter library: \d+: unexpected token at '{ \"company\": \"Example, Inc.\",'/), e.message
  end

end
