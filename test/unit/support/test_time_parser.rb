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

require_relative '../../../lib/armagh/support/time_parser'

class TestTime < Test::Unit::TestCase

  def setup
    @config_store = []
    @default_config = Armagh::Support::TimeParser.create_configuration( @config_store, 'default', { 'time_parser' => { 'time_format' => '%m/%d/%Y'}} )
    @config_with_custom_time_format = Armagh::Support::TimeParser.create_configuration( @config_store, 'custom_time_format', { 'time_parser' => {'time_format' => '%H|%M|%S'}} )
    @config_without_time_format = Armagh::Support::TimeParser.create_configuration( @config_store, 'no_time_format', {} )
  end

  test "parses a time that's properly formatted" do
    time = Time.now.to_s
    parsed_time = Armagh::Support::TimeParser.parse_time(time, @default_config)
    assert_equal parsed_time, Time.parse(time)
  end

  test "parses a datetime that's properly formatted" do
    time = DateTime.now.to_s
    parsed_time = Armagh::Support::TimeParser.parse_time(time, @default_config)
    assert_equal parsed_time, Time.parse(time)
  end

  test "parses a date using time format specified in config and set time to 00 hours UTC" do
    time = "05/30/2014"
    parsed_time = Armagh::Support::TimeParser.parse_time(time, @default_config)
    assert parsed_time.is_a?(Time)
    assert_equal parsed_time.utc.mon,  5
    assert_equal parsed_time.utc.day,  30
    assert_equal parsed_time.utc.year, 2014
    assert_equal parsed_time.utc.hour, 0
    assert_equal parsed_time.utc.min,  0
    assert_equal parsed_time.utc.sec,  0
  end

  test "parses a time matching the format specified in config" do
    time = "10|30|00"

    parsed_time = Armagh::Support::TimeParser.parse_time(time, @config_with_custom_time_format)
    assert parsed_time.is_a?(Time)
    assert_equal parsed_time.hour, 10
    assert_equal parsed_time.min,  30
    assert_equal parsed_time.sec,  0
  end

  test "raises an exception if time argument isn't a string" do
    invalid_time = {}
    assert_raise Armagh::Support::TimeParser::TypeMismatchError do
      Armagh::Support::TimeParser.parse_time(invalid_time, @default_config)
    end
  end

  test "raises an exception if time argument can't be parsed as a time" do
    invalid_time = ""
    assert_raise Armagh::Support::TimeParser::UnparsableTimeError do
      Armagh::Support::TimeParser.parse_time(invalid_time, @default_config)
    end
  end

end

