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
    @source_encodings_path = File.join @fixtures_path, 'source_encodings'

    @expected_content_path = File.join(@fixtures_path, 'expected_output')
    @default_json = File.join @fixtures_path, 'test.json'

    @expected_divided_content = load_expected_content(File.join(@expected_content_path, 'expected_divided_content.yml'))

    @default_options = {'size_per_part' => 250, 'divide_target' => 'employees'}
  end

  def test_company_UTF_8
    json = @default_json
    actual_divided_content = []
    options = { 'size_per_part' => 250, 'divide_target' => 'employees', 'source_encoding' => 'UTF-8' }

    JSONDivider.new(json, options).divide do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > 250}
    assert_equal JSON.parse(File.read(json)), combine_parts(actual_divided_content)
  end

  def test_company_ASCII
    json = @default_json
    actual_divided_content = []
    options = { 'size_per_part' => 250, 'divide_target' => 'employees', 'source_encoding' => 'ASCII' }

    JSONDivider.new(json, options).divide do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > 250}
    assert_equal JSON.parse(File.read(json)), combine_parts(actual_divided_content)
  end

  def test_company_US_ASCII
    json = @default_json
    actual_divided_content = []
    options = { 'size_per_part' => 250, 'divide_target' => 'employees', 'source_encoding' => 'US-ASCII' }

    JSONDivider.new(json, options).divide do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > 250}
    assert_equal JSON.parse(File.read(json)), combine_parts(actual_divided_content)
  end

  def test_company_ASCII_8BIT
    json = @default_json
    actual_divided_content = []
    options = { 'size_per_part' => 250, 'divide_target' => 'employees', 'source_encoding' => 'ASCII-8BIT' }

    JSONDivider.new(json, options).divide do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > 250}
    assert_equal JSON.parse(File.read(json)), combine_parts(actual_divided_content)
  end

  def test_raise_when_file_not_found
    assert_raise JSONDivider::JSONDividerError do
      JSONDivider.new('unknown_file', @default_options)
    end
  end

  def test_raise_when_invalid_source_encoding
    options = @default_options.merge({ 'source_encoding' => 'invalid source_encoding' })
    assert_raise JSONDivider::JSONDividerError do
      JSONDivider.new(@default_json, options)
    end
  end

  def test_raise_when_size_per_part_not_int
    options = { 'size_per_part' => Object.new, 'divide_target' => 'employees' }
    assert_raise JSONDivider::JSONDividerError do
      JSONDivider.new(@default_json, options)
    end
  end

  def test_raise_when_size_per_part_negative
    options = { 'size_per_part' => -100, 'divide_target' => 'employees' }
    assert_raise JSONDivider::JSONDividerError do
      JSONDivider.new(@default_json, options)
    end
  end

  def test_raise_when_size_per_part_zero
    options = { 'size_per_part' => 0, 'divide_target' => 'employees' }
    assert_raise JSONDivider::JSONDividerError do
      JSONDivider.new(@default_json, options)
    end
  end

  def test_raise_when_divide_target_not_String
    options = { 'size_per_part' => 250, 'divide_target' => Object.new }
    assert_raise JSONDivider::JSONDividerError do
      JSONDivider.new(@default_json, options)
    end
  end

  def test_raise_when_divide_target_blank
    options = { 'size_per_part' => 250, 'divide_target' => '     ' }
    assert_raise JSONDivider::JSONDividerError do
      JSONDivider.new(@default_json, options)
    end
  end

  def test_raise_when_divide_target_cannot_be_converted_to_source_encoding
    options = { 'source_encoding' => 'ISO-8859-1', 'size_per_part' => 250, 'divide_target' => 'three_ä_non_Ģ_ascii_Ž_chars' }
    assert_raise JSONDivider::JSONDividerError do
      JSONDivider.new(@default_json, options)
    end
  end

  def test_header_returns_header_string
    json = @default_json
    expected_header = "{ \"company\": \"Example, Inc.\", \"address\": \"123 Main St, New York, NY 12345\", \"stock symbol\": \"XMPL\", \"employees\" : ["

    divider = JSONDivider.new(json, @default_options)
    divider.divide {}

    assert_equal expected_header, divider.header
  end

  def test_footer_returns_footer_string
    json = @default_json
    expected_footer = "]}\n"

    divider = JSONDivider.new(json, @default_options)
    divider.divide {}

    assert_equal expected_footer, divider.footer
  end

  def test_raises_an_exception_if_header_is_greater_than_max_size_per_part
    json = @default_json

    divider = JSONDivider.new(json, @default_options)
    divider.stubs(:header_size).at_least_once.returns(1_000_000)

    assert_raise JSONDivider::SizeError do
      divider.divide {}
    end
  end

  def test_raises_an_exception_if_footer_is_greater_than_max_size
    json = @default_json

    divider = JSONDivider.new(json, @default_options)
    divider.stubs(:footer_size).at_least_once.returns(1_000_000)

    assert_raise JSONDivider::SizeError do
      divider.divide {}
    end
  end

  def test_raises_an_exception_if_header_footer_is_greater_than_max_size
    json = @default_json

    divider = JSONDivider.new(json, @default_options)
    divider.stubs(:header_footer_size).at_least_once.returns(1_000_000)

    assert_raise JSONDivider::SizeError do
      divider.divide {}
    end
  end

  def test_raises_an_exception_if_we_read_the_first_max_size_bytes_and_divide_target_isnt_found
    json = File.join @fixtures_path, 'too_large.json'
    options = @default_options.merge({ 'size_per_part' => 100 })

    divider = JSONDivider.new(json, options)

    assert_raise JSONDivider::DivideTargetNotFoundInFirstChunkError do
      divider.divide {}
    end
  end

  def test_divide_target_is_not_counted_as_found_if_that_string_is_also_present_in_part_of_the_JSON_prior_to_the_opening_bracket_for_the_actual_divide_target
    json = File.join @fixtures_path, 'test_with_divide_target_string.json'
    options = @default_options.merge({ 'size_per_part' => 65 })

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
    options = @default_options.merge({ 'size_per_part' => max_part_size })

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
    options = @default_options.merge({ 'size_per_part' => max_part_size })

    divider = JSONDivider.new(json, options)
    divider.divide do |part|
      actual_divided_content << part
    end

    first_part = actual_divided_content.first
    first_part_hash = JSON.parse(first_part)
    name = first_part_hash['employees'].first["name"]

    assert_equal expected_divided_content, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > max_part_size}
    assert_equal JSON.parse(File.read(json)), combine_parts(actual_divided_content)
    assert_equal 'Brian [Senior " Manager]', name
  end

  def test_raises_exception_if_size_per_part_is_too_small_to_divide_JSON_file
    json = File.join @fixtures_path, 'test_with_line_breaks.json'

    divider = JSONDivider.new(json, @default_options)

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
    options = { 'divide_target' => 'employees', 'size_per_part' => size_per_part  }

    JSONDivider.new(json, options).divide do |part|
      actual_divided_content << part
    end
    actual_divided_content_real_hashes = actual_divided_content.map { |part| JSON.parse part }

    assert_equal n_expected_parts, actual_divided_content.size, "expected #{n_expected_parts} parts"
    assert_equal expected_divided_content, actual_divided_content_real_hashes
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > size_per_part}
    assert_equal JSON.parse(File.read(json)), combine_parts(actual_divided_content)
  end

  def test_ext_json_divide_not_called_if_file_size_less_eq_size_per_part
    json = @default_json
    expected_content = File.read(json)

    actual_divided_content = []
    size_per_part = expected_content.bytesize + 1
    divide_target = 'it doesn\'t matter'
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target}

    divider = JSONDivider.new(json, options)
    divider.expects(:ext_json_divide).never
    divider.divide do |part|
      actual_divided_content << part
    end

    assert_equal 1,                actual_divided_content.size
    assert_equal expected_content, actual_divided_content[0]
  end

  def test_raise_exception_if_invalid_regex_because_of_divide_target
    json = @default_json

    size_per_part = 120
    divide_target = 'employees[abc'
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target}

    divider = JSONDivider.new(json, options)

    assert_raise JSONDivider::ExtJSONDividerError do
      divider.divide {}
    end
  end

  def test_raise_exception_if_divide_target_not_found
    json = @default_json

    size_per_part = 120
    divide_target = 'NOT_employees'
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target}

    divider = JSONDivider.new(json, options)

    assert_raise JSONDivider::DivideTargetNotFoundInFirstChunkError do
      divider.divide {}
    end
  end

  def test_raise_exception_if_footer_too_large
    json = File.join @fixtures_path, 'test_footer_too_large.json'

    size_per_part = 120
    divide_target = 'employees'
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target}

    divider = JSONDivider.new(json, options)

    assert_raise JSONDivider::SizeError do
      divider.divide {}
    end
  end

  def test_raise_exception_if_invalid_json_nonterminating_string
    json = File.join @fixtures_path, 'test_invalid_nonterminating_string.json'

    size_per_part = 200
    divide_target = 'employees'
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target}

    divider = JSONDivider.new(json, options)

    assert_raise JSONDivider::JSONParseError do
      divider.divide {}
    end
  end

  def test_raise_exception_if_invalid_json_nonterminating_hash
    json = File.join @fixtures_path, 'test_invalid_nonterminating_hash.json'

    size_per_part = 200
    divide_target = 'employees'
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target}

    divider = JSONDivider.new(json, options)

    assert_raise JSONDivider::JSONParseError do
      divider.divide {}
    end
  end

  def test_raise_exception_if_invalid_json_nonterminating_internal_array
    json = File.join @fixtures_path, 'test_invalid_nonterminating_internal_array.json'

    size_per_part = 200
    divide_target = 'employees'
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target}

    divider = JSONDivider.new(json, options)

    assert_raise JSONDivider::JSONParseError do
      divider.divide {}
    end
  end

  def test_raise_exception_if_invalid_json_nonterminating_divide_target_array
    json = File.join @fixtures_path, 'test_invalid_nonterminating_divide_target_array.json'

    size_per_part = 200
    divide_target = 'employees'
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target}

    divider = JSONDivider.new(json, options)

    assert_raise JSONDivider::JSONParseError do
      divider.divide {}
    end
  end

  def test_original_UTF8_source_file
    json = File.join @source_encodings_path, 'test_encoding_UTF-8_3_non_ascii.json'

    expected_header = <<-EOS
{ "stuff_in_header": {
    "hi": "there"
  },
  "this is not \\\"three_ä_non_Ģ_ascii_Ž_chars": [
    { "not claim": {
        "not id": "998"
      }
    },
    { "not claim": {
       "not id": "999"
      }
    }
  ],
  "three_ä_non_Ģ_ascii_Ž_chars": [
EOS
    expected_header.sub!(/\n$/, '')

    expected_footer = <<-EOS
],
  "stuff_in_footer": {
    "hello": "world"
    "UTF-8": "three_ä_non_Ģ_ascii_Ž_chars"
  }
}
EOS

    expected_element_1 = <<-EOS
{ "claim": {
        "id":   "111",
        "bill": "b111",
        "hash": {
          "stuff": "in hash"
        }
      }
    }
EOS
    expected_element_2 = <<-EOS
{ "claim": {
        "id":   "222",
        "bill": "b222",
        "str":  "str three_ä_non_Ģ_ascii_Ž_chars str"
      }
    }
EOS
    expected_element_3 = <<-EOS
{ "claim": {
        "id":   "333",
        "bill": "b333"
      }
    }
EOS
    expected_element_4 = <<-EOS
{ "claim": {
        "id":   "444",
        "bill": "b444",
        "ary":  [
          {"id": "ary1"},
          {"id": "ary2"},
          {"id": "ary3"}
        ]
      }
    }
EOS
    expected_element_1.sub!(/\n$/, '')
    expected_element_2.sub!(/\n$/, '')
    expected_element_3.sub!(/\n$/, '')
    expected_element_4.sub!(/\n$/, '')

    expected_part_1 = "#{expected_header}#{expected_element_1}#{expected_footer}"
    expected_part_2 = "#{expected_header}#{expected_element_2},#{expected_element_3}#{expected_footer}"
    expected_part_3 = "#{expected_header}#{expected_element_4}#{expected_footer}"

    actual_divided_content = []
    size_per_part = 600
    divide_target = 'three_ä_non_Ģ_ascii_Ž_chars'
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target}

    divider = JSONDivider.new(json, options)
    divider.divide do |part|
      actual_divided_content << part
    end

    assert_equal expected_header, divider.header
    assert_equal expected_footer, divider.footer
    assert_equal 3,               actual_divided_content.size
    assert_equal expected_part_1, actual_divided_content[0]
    assert_equal expected_part_2, actual_divided_content[1]
    assert_equal expected_part_3, actual_divided_content[2]
  end

  def test_encoding_UTF_8
    setup_source_encoding_vars
    validate_source_encoding_test('UTF-8')
  end

  def test_encoding_ISO_8859_1
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('ISO-8859-1')
  end

  def test_encoding_Windows_1251
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('Windows-1251')
  end

  def test_encoding_Windows_1252
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('Windows-1252')
  end

  def test_encoding_GB2312
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('GB2312')
  end

  def test_encoding_EUC_KR
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('EUC-KR')
  end

  def test_encoding_EUC_JP
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('EUC-JP')
  end

  def test_encoding_GBK
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('GBK')
  end

  def test_encoding_ISO_8859_2
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('ISO-8859-2')
  end

  def test_encoding_Windows_1250
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('Windows-1250')
  end

  def test_encoding_ISO_8859_15
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('ISO-8859-15')
  end

  def test_encoding_Windows_1256
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('Windows-1256')
  end

  def test_encoding_ISO_8859_9
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('ISO-8859-9')
  end

  def test_encoding_Big5
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('Big5')
  end

  def test_encoding_Windows_1254
    setup_source_encoding_vars
    validate_source_encoding_test_ruby_divide_not_yet_implemented('Windows-1254')
  end

  def test_encoding_Windows_874
    setup_source_encoding_vars

    source_encoding = 'Windows-874'
    divide_target = @UTF8_divide_target
    json = File.join @source_encodings_path, "test_encoding_#{source_encoding}.json"

    actual_divided_content = []
    size_per_part = 550
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target, 'source_encoding' => source_encoding}

    ## will raise because @UTF8_divide_target cannot be converted to Windows-874
    assert_raise JSONDivider::JSONDividerError do
      divider = JSONDivider.new(json, options)
    end
  end

  def test_encoding_ASCII
    setup_source_encoding_vars

    source_encoding = 'ASCII'
    divide_target = @UTF8_divide_target
    json = File.join @source_encodings_path, "test_encoding_#{source_encoding}.json"

    actual_divided_content = []
    size_per_part = 550
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target, 'source_encoding' => source_encoding}

    ## will raise because @UTF8_divide_target cannot be converted to Windows-874
    assert_raise JSONDivider::JSONDividerError do
      divider = JSONDivider.new(json, options)
    end
  end

  def test_encoding_US_ASCII
    setup_source_encoding_vars

    source_encoding = 'US-ASCII'
    divide_target = @UTF8_divide_target
    json = File.join @source_encodings_path, "test_encoding_#{source_encoding}.json"

    actual_divided_content = []
    size_per_part = 550
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target, 'source_encoding' => source_encoding}

    ## will raise because @UTF8_divide_target cannot be converted to Windows-874
    assert_raise JSONDivider::JSONDividerError do
      divider = JSONDivider.new(json, options)
    end
  end

  def test_encoding_ASCII_8BIT
    setup_source_encoding_vars

    source_encoding = 'ASCII-8BIT'
    divide_target = @UTF8_divide_target
    json = File.join @source_encodings_path, "test_encoding_#{source_encoding}.json"

    actual_divided_content = []
    size_per_part = 550
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target, 'source_encoding' => source_encoding}

    ## will raise because @UTF8_divide_target cannot be converted to Windows-874
    assert_raise JSONDivider::JSONDividerError do
      divider = JSONDivider.new(json, options)
    end
  end



  def validate_source_encoding_test(source_encoding)
    divide_target = @UTF8_divide_target
    json = File.join @source_encodings_path, "test_encoding_#{source_encoding}.json"

    actual_divided_content = []
    size_per_part = 550
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target, 'source_encoding' => source_encoding}

    divider = JSONDivider.new(json, options)
    divider.divide do |part|
      actual_divided_content << part
    end

    assert_equal @expected_UTF8_header, divider.header,               source_encoding
    assert_equal @expected_UTF8_footer, divider.footer,               source_encoding
    assert_equal 3,                      actual_divided_content.size, source_encoding
    assert_equal @expected_UTF8_part_1, actual_divided_content[0],    source_encoding
    assert_equal @expected_UTF8_part_2, actual_divided_content[1],    source_encoding
    assert_equal @expected_UTF8_part_3, actual_divided_content[2],    source_encoding
  end

  def validate_source_encoding_test_ruby_divide_not_yet_implemented(source_encoding)
    divide_target = @UTF8_divide_target
    json = File.join @source_encodings_path, "test_encoding_#{source_encoding}.json"

    actual_divided_content = []
    size_per_part = 550
    options = {'size_per_part' => size_per_part, 'divide_target' => divide_target, 'source_encoding' => source_encoding}

    ## current code raises ruby JSON divider not yet implemented
    divider = JSONDivider.new(json, options)
    assert_raise JSONDivider::JSONDividerError do
      divider.divide {}
    end
  end

  def setup_source_encoding_vars
    @UTF8_divide_target = 'non_ascii_°_char'

    @expected_UTF8_header = <<-EOS
{ "stuff_in_header": {
    "hi": "there"
  },
  "this is not \\\"non_ascii_°_char": [
    { "not claim": {
        "not id": "998"
      }
    },
    { "not claim": {
       "not id": "999"
      }
    }
  ],
  "non_ascii_°_char": [
EOS
    @expected_UTF8_header.sub!(/\n$/, '')

    @expected_UTF8_footer = <<-EOS
],
  "stuff_in_footer": {
    "hello": "world"
    "UTF-8": "non_ascii_°_char"
  }
}
EOS

    @expected_UTF8_element_1 = <<-EOS
{ "claim": {
        "id":   "111",
        "bill": "b111",
        "hash": {
          "stuff": "in hash"
        }
      }
    }
EOS
    @expected_UTF8_element_2 = <<-EOS
{ "claim": {
        "id":   "222",
        "bill": "b222",
        "str":  "str non_ascii_°_char str"
      }
    }
EOS
    @expected_UTF8_element_3 = <<-EOS
{ "claim": {
        "id":   "333",
        "bill": "b333"
      }
    }
EOS
    @expected_UTF8_element_4 = <<-EOS
{ "claim": {
        "id":   "444",
        "bill": "b444",
        "ary":  [
          {"id": "ary1"},
          {"id": "ary2"},
          {"id": "ary3"}
        ]
      }
    }
EOS
    @expected_UTF8_element_1.sub!(/\n$/, '')
    @expected_UTF8_element_2.sub!(/\n$/, '')
    @expected_UTF8_element_3.sub!(/\n$/, '')
    @expected_UTF8_element_4.sub!(/\n$/, '')

    @expected_UTF8_part_1 = "#{@expected_UTF8_header}#{@expected_UTF8_element_1}#{@expected_UTF8_footer}"
    @expected_UTF8_part_2 = "#{@expected_UTF8_header}#{@expected_UTF8_element_2},#{@expected_UTF8_element_3}#{@expected_UTF8_footer}"
    @expected_UTF8_part_3 = "#{@expected_UTF8_header}#{@expected_UTF8_element_4}#{@expected_UTF8_footer}"
  end

end
