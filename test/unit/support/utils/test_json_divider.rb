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

require_relative '../../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'
require 'yaml'

require_relative '../../../../lib/armagh/support/utils/json_divider/'
require_relative '../../../helpers/json_test_helpers'


class TestJSONDivider < Test::Unit::TestCase
  include JSONTestHelpers

  def setup
    @fixtures_path = File.join(__dir__, '..', '..', '..', 'fixtures', 'json')

    @expected_content_path = File.join(@fixtures_path, 'expected_output')
    @default_json = File.join @fixtures_path, 'test.json'

    @expected_divided_content = load_expected_content(File.join(@expected_content_path, 'expected_divided_content.yml'))
  end

  def test_when_no_options_are_specified_divides_source_json_using_first_array_node_as_the_divide_target
    json = @default_json
    actual_divided_content = []
    options = { }

    JSONDivider.new(json, options).divide do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > 250}
    assert_equal JSON.parse(File.read(json)), combine_parts(actual_divided_content)
  end

  def test_when_config_specifies_a_divide_target_divides_source_json_using_that_divide_target
    json = @default_json
    actual_divided_content = []
    options = { "divide_target": "employees" }

    JSONDivider.new(json, options).divide do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > 250}
    assert_equal JSON.parse(File.read(json)), combine_parts(actual_divided_content)
  end

  def test_#header_returns_header_string
    json = @default_json
    options = { }
    expected_header = "{ \"company\": \"Example, Inc.\", \"address\": \"123 Main St, New York, NY 12345\", \"stock symbol\": \"XMPL\", \"employees\" : ["

    divider = JSONDivider.new(json, options)
    divider.divide {}

    assert_equal expected_header, divider.header
  end

  def test_footer_returns_footer_string
    json = @default_json
    options = { }
    expected_footer = "]}\n"

    divider = JSONDivider.new(json, options)
    divider.divide {}

    assert_equal expected_footer, divider.footer
  end

  def test_raises_an_exception_if_header_is_greater_than_max_size_per_part
    json = @default_json
    options = { }

    divider = JSONDivider.new(json, options)
    divider.stubs(:header_size).at_least_once.returns(1_000_000)

    assert_raise JSONDivider::SizeError do
      divider.divide {}
    end
  end

  def test_raises_an_exception_if_footer_is_greater_than_max_size
    json = @default_json
    options = { }

    divider = JSONDivider.new(json, options)
    divider.stubs(:footer_size).at_least_once.returns(1_000_000)

    assert_raise JSONDivider::SizeError do
      divider.divide {}
    end
  end

  def test_raises_an_exception_if_header_footer_is_greater_than_max_size
    json = @default_json
    options = { }

    divider = JSONDivider.new(json, options)
    divider.stubs(:header_footer_size).at_least_once.returns(1_000_000)

    assert_raise JSONDivider::SizeError do
      divider.divide {}
    end
  end

  def test_raises_an_exception_if_we_read_the_first_max_size_bytes_and_divide_target_isnt_found
    json = @default_json
    options = { "size_per_part" => 100 }

    divider = JSONDivider.new(json, options)
    divider.stubs(:buffer_size).at_least_once.returns(100)

    assert_raise JSONDivider::DivideTargetNotFoundInFirstChunkError do
      divider.divide {}
    end
  end

  def test_divide_target_is_not_counted_as_found_if_that_string_is_also_present_in_part_of_the_JSON_prior_to_the_opening_bracket_for_the_actual_divide_target
    json = File.join @fixtures_path, 'test_with_divide_target_string.json'
    options = { "size_per_part" => 65 }

    divider = JSONDivider.new(json, options)

    assert_raise JSONDivider::DivideTargetNotFoundInFirstChunkError do
      divider.divide {}
    end
  end

  def test_divides_pretty_fied_json_that_includes_line_breaks
    json = File.join @fixtures_path, 'test_with_line_breaks.json'
    actual_divided_content = []
    max_part_size = 325
    expected_divided_content = load_expected_content(File.join(@expected_content_path, 'expected_divided_content_with_line_breaks.yml'))
    options = { "size_per_part" => max_part_size  }

    divider = JSONDivider.new(json, options)
    divider.divide do |part|
      actual_divided_content << part
    end

    assert_equal expected_divided_content, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > max_part_size}
    assert_equal JSON.parse(File.read(json)), combine_parts(actual_divided_content)
  end

  def test_divides_json_that_includes_brackets_etc_inside_double_quoted_strings
    json = File.join @fixtures_path, 'test_with_brackets_in_strings.json'
    actual_divided_content = []
    max_part_size = 355
    expected_divided_content = load_expected_content(File.join(@expected_content_path, 'expected_divided_content_with_brackets_in_strings.yml'))
    options = { "size_per_part" => max_part_size  }

    divider = JSONDivider.new(json, options)
    divider.divide do |part|
      actual_divided_content << part
    end

    first_part = actual_divided_content.first
    first_part_hash = JSON.parse(first_part)
    name = first_part_hash["employees"].first["name"]

    assert_equal expected_divided_content, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > max_part_size}
    assert_equal JSON.parse(File.read(json)), combine_parts(actual_divided_content)
    assert_equal 'Brian [Senior " Manager]', name
  end

  def test_raises_exception_if_size_per_part_is_too_small_to_divide_JSON_file
    json = File.join @fixtures_path, 'test_with_line_breaks.json'
    options = { }

    divider = JSONDivider.new(json, options)

    assert_raise JSONDivider::SizePerPartTooSmallError do
      divider.divide {}
    end
  end

  def test_nested_hashes
    json = File.join @fixtures_path, 'nested_hash.json'
    expected_divided_content = JSON.parse(File.read(File.join @expected_content_path, 'expected_divided_nested_hash.json'))
    n_expected_parts = expected_divided_content.size

    actual_divided_content = []
    size_per_part = 1000
    options = { "divide_target" => "employees", "size_per_part" => size_per_part  }

    JSONDivider.new(json, options).divide do |part|
      actual_divided_content << part
    end
    actual_divided_content_real_hashes = actual_divided_content.map { |part| JSON.parse part }

    assert_equal n_expected_parts, actual_divided_content.size, "expected #{n_expected_parts} parts"
    assert_equal expected_divided_content, actual_divided_content_real_hashes
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > size_per_part}
    assert_equal JSON.parse(File.read(json)), combine_parts(actual_divided_content)
  end

end
