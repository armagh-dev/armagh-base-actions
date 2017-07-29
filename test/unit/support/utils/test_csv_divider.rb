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

require_relative '../../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'
require 'yaml'

require_relative '../../../../lib/armagh/support/utils/csv_divider/'


module CSVTestHelpers
  def combine_parts(parts)
    parts.inject("") do |complete_content, part|
      part = remove_header_from_part(part) if !complete_content.empty?
      complete_content << part
    end
  end

  def remove_header_from_part(part)
    rows = part.split("\n")
    rows.shift
    rows.join("\n") + "\n"
  end

  def parts_sizes(parts)
    parts.each_with_object([]) do |part, ary|
      if ary.empty?
        ary << part.size
      else
        rows = part.split("\n")
        rows.shift
        part = rows.join
        ary << part.size
      end
    end
  end

  def load_expected(file_path)
    YAML.load_file(file_path)["content"]
  end

end

class TestCsvDivider < Test::Unit::TestCase
  include CSVTestHelpers

  def setup
    fixtures_path = File.join(__dir__, '..', '..', '..', 'fixtures', 'csv')
    expected_content_path = File.join(fixtures_path, 'expected_output')
    @csv = File.join fixtures_path, 'test.csv'
    @csv_with_pipe_column_separator = File.join fixtures_path, 'csv_with_pipe_column_separator.csv'
    @csv_with_double_pipe_row_separator = File.join fixtures_path, 'csv_with_double_pipe_row_separator.csv'
    @csv_with_quote_character = File.join fixtures_path, 'csv_with_quote_character.csv'
    @csv_with_quoted_row_sep = File.join fixtures_path, 'csv_with_quoted_row_sep.csv'
    @csv_row_with_missing_value_path     = File.join fixtures_path, 'row_with_missing_value.csv'
    @csv_row_with_extra_values_path      = File.join fixtures_path, 'row_with_extra_values.csv'

    @expected_divided_content                     = YAML.load_file(File.join(expected_content_path, 'expected_divided_content.yml'))["content"]
    @expected_divided_content_with_quote_char     = YAML.load_file(File.join(expected_content_path, 'expected_divided_content_with_quote_char.yml'))["content"]
    @expected_divided_content_malformed_row       = YAML.load_file(File.join(expected_content_path, 'expected_divided_content_malformed_row.yml'))["content"]
    @expected_divided_content_double_pipe_row_sep = YAML.load_file(File.join(expected_content_path, 'expected_divided_content_double_pipe_row_sep.yml'))["content"]
    @expected_divided_content_pipe_col_sep        = YAML.load_file(File.join(expected_content_path, 'expected_divided_content_pipe_col_sep.yml'))["content"]

    #TODO (KN): not sure if we're going to be using the items commented out below...wip

    # @csv_with_extra_values_last_row_path = File.join fixtures_path, 'extra_values_on_last_row.csv'
    # @csv_with_newline_in_field           = File.join fixtures_path, 'newline_in_field.csv'
    # @csv_with_non_standard_padding_rows  = File.join fixtures_path, 'non_standard_padding_rows.csv'
    # @csv_malformed                       = File.join fixtures_path, 'malformed_test.csv'


    # @expected_divided_content_malformed_last_row = ["Name,Email,Phone\nBrian,brian@example.com,555-1212\nChuck,chuck@example.com,555-1212\n",
    #                                                 "Name,Email,Phone\nDale,dale@example.com,555-1212\nEric,eric@example.com,555-1212\nFrank,frank@example.com,555-1212\n",
    #                                                 "Name,Email,Phone\nGeorge,george@example.com,555-1212\nHenry,henry@example.com,555-1212\nIvan,ivan@example.com,555-1212\n",
    #                                                 "Name,Email,Phone\nJack,jack@example.com,555-1212\nKen,ken@example.com,555-1212\nLarry,larry@example.com,555-1212\n",
    #                                                 "Name,Email,Phone\nMike,mike@example.com,555-1212\nBob,bob@example.com,555-1212\nJoe,joe@example.com,555-1212\n",
    #                                                 "Name,Email,Phone\nJane,jane@example.com,555-1212\nPaul,paul@example.com,555-1212\nSame,same@example.com,555-1212\n",
    #                                                 "Name,Email,Phone\nBill,bill@example.com,555-1212\nJim,jim@example.com,555-1212\nKevin,kevin@example.com,555-1212\n",
    #                                                 "Name,Email,Phone\nFoo,foo@example.com,555-1212,foo,bar,foo,baz,foo,bar\n"]

    # @expected_divided_content_newline_in_field = ["Name,Email,Phone\nBrian,brian@example.com,555-1212\nChuck,chuck\\n@example.com,555-1212\n",
    #                                               "Name,Email,Phone\nDale,dale@example.com,555-1212\nEric,eric@example.com,555-1212\nFrank,frank@example.com,555-1212\n",
    #                                               "Name,Email,Phone\nGeorge,george@example.com,555-1212\nHenry,henry@example.com,555-1212\nIvan,ivan@example.com,555-1212\n",
    #                                               "Name,Email,Phone\nJack,jack@example.com,555-1212\nKen,ken@example.com,555-1212\nLarry,larry@example.com,555-1212\n",
    #                                               "Name,Email,Phone\nMike,mike@example.com,555-1212\nBob,bob@example.com,555-1212\nJoe,joe@example.com,555-1212\n",
    #                                               "Name,Email,Phone\nJane,jane@example.com,555-1212\nPaul,paul@example.com,555-1212\nSame,same@example.com,555-1212\n",
    #                                               "Name,Email,Phone\nBill,bill@example.com,555-1212\nJim,jim@example.com,555-1212\nKevin,kevin@example.com,555-1212\n"]

  end

  test "when no options are specified, divides source csv into array of multiple csv strings using default options" do
    actual_divided_content = []
    expected_divided_content = YAML.load_file('test/fixtures/csv/expected_output/expected_divided_content.yml')["content"]
    options = { }

    CSVDivider.new(@csv, options).divide do |part|
      actual_divided_content << part
    end

    assert_equal expected_divided_content, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > 100}
  end

  test "when size_per_part is specified, divides csv into array of csv strings having that max size" do
    actual_divided_content = []
    options = { 'size_per_part'  => 100 }

    CSVDivider.new(@csv, options).divide do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > 100}
  end

  test "when col_sep is specified, divides csv into array of csv strings using that column separator" do
    actual_divided_content = []
    expected_divided_content = @expected_divided_content_pipe_col_sep
    options = { 'col_sep'  => '|' }

    CSVDivider.new(@csv_with_pipe_column_separator, options).divide do |part|
      actual_divided_content << part
    end

    assert_equal expected_divided_content, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > 100}
  end

  test "when row_sep is specified, divides csv into array of csv strings using that row separator" do
    actual_divided_content = []
    expected_divided_content = @expected_divided_content_double_pipe_row_sep
    options = { 'row_sep'  => '||' }

    CSVDivider.new(@csv_with_double_pipe_row_separator, options).divide do |part|
      actual_divided_content << part
    end

    assert_equal expected_divided_content, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > 100}
  end

  test "when quote_char is specified, divides csv into array of csv strings using that quote character" do
    actual_divided_content = []
    options = { 'quote_char'  => '"' }

    CSVDivider.new(@csv_with_quote_character, options).divide do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content_with_quote_char, actual_divided_content
    assert_equal false, parts_sizes(actual_divided_content).any? {|x| x > 100}
  end

  test "raises an exception when a csv row is missing a value" do
    options = {}
    assert_raise CSVDivider::RowMissingValueError do
      CSVDivider.new(@csv_row_with_missing_value_path, options).divide do |part|
      end
    end
  end

  test "raises an exception when a csv row is has extra values" do
    options = {}
    assert_raise CSVDivider::RowWithExtraValuesError do
      CSVDivider.new(@csv_row_with_extra_values_path, options).divide do |part|
      end
    end
  end

  #TODO: wip - all of the tests below are pulled from CSVDivide's tests
  #to be reimplemented here
  #
  # test "properly divides source csv when row contains extra values" do
  #   actual_divided_content = []
  #   options = {}

  #   CSVDivider.new(@csv_row_with_extra_values_path, options).divide do |part|
  #     actual_divided_content << part
  #   end

  #   assert_equal @expected_divided_content_malformed_row, actual_divided_content
  #   assert_equal false, parts_sizes(actual_divided_content).map(&:size).any? {|x| x > 100}
  # end

  # test "properly divides source csv when row contains newline in one of its fields" do
  #   actual_divided_content = []

  #   CSVDivider.new(@csv_with_newline_in_field, @config_size_100) do |part|
  #     actual_divided_content << part
  #   end

  #   assert_equal @expected_divided_content_newline_in_field, actual_divided_content
  #   assert_equal false, Armagh::Support::CSV.parts_sizes(actual_divided_content).map(&:size).any? {|x| x > 100}
  # end

  # test "when csv has row with extra values, divided parts match source csv when recombined" do
  #   expected_combined_content = IO.binread(@csv_row_with_extra_values_path)
  #   divided_content = []

  #   CSVDivider.new(@csv_row_with_extra_values_path, @config_size_100) do |part|
  #     divided_content << part
  #   end

  #   assert_equal expected_combined_content, combine_parts(divided_content)
  # end

  # test "when csv is well-formed, divided parts match source csv when recombined" do
  #   expected_combined_content = IO.binread(@csv)
  #   divided_content = []

  #   CSVDivider.new(@csv, @config_size_100) do |part|
  #     divided_content << part
  #   end

  #   assert_equal expected_combined_content, combine_parts(divided_content)
  # end

  # test "when csv has field with a newline, divided parts match source csv when recombined" do
  #   expected_combined_content = IO.binread(@csv_with_newline_in_field)
  #   divided_content = []

  #   CSVDivider.new(@csv_with_newline_in_field, @config_size_100) do |part|
  #     divided_content << part
  #   end

  #   assert_equal expected_combined_content, combine_parts(divided_content)
  # end

  test "dividing returns an error when block isn't passed in" do
    options = {}

    assert_raise(LocalJumpError) {
      CSVDivider.new(@csv, options).divide
    }
  end

end

