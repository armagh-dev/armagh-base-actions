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

require_relative '../../../lib/armagh/support/csv'


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

  def doc_from_fixture(fixture)
    source = File.read(fixture)
    content = {'bson_binary' => BSON::Binary.new(source) }
    doc = mock('document')
    doc.stubs(:raw).returns(source)
    doc.stubs(:content).returns(content)
    doc
  end
end

class TestCsv < Test::Unit::TestCase
  include CSVTestHelpers
  include Armagh::Support::CSV

  def setup
    fixtures_path = File.join(__dir__, '..', '..', 'fixtures', 'csv')
    @csv = File.join fixtures_path, 'test.csv'
    @csv_row_with_missing_value_path     = File.join fixtures_path, 'row_with_missing_value.csv'
    @csv_row_with_extra_values_path      = File.join fixtures_path, 'row_with_extra_values.csv'
    @csv_with_extra_values_last_row_path = File.join fixtures_path, 'extra_values_on_last_row.csv'
    @csv_with_newline_in_field           = File.join fixtures_path, 'newline_in_field.csv'
    @csv_with_non_standard_padding_rows  = File.join fixtures_path, 'non_standard_padding_rows.csv'
    @csv_malformed                       = File.join fixtures_path, 'malformed_test.csv'

    @expected_divided_content = ["Name,Email,Phone\nBrian,brian@example.com,555-1212\nChuck,chuck@example.com,555-1212\n",
                                 "Name,Email,Phone\nDale,dale@example.com,555-1212\nEric,eric@example.com,555-1212\nFrank,frank@example.com,555-1212\n",
                                 "Name,Email,Phone\nGeorge,george@example.com,555-1212\nHenry,henry@example.com,555-1212\nIvan,ivan@example.com,555-1212\n",
                                 "Name,Email,Phone\nJack,jack@example.com,555-1212\nKen,ken@example.com,555-1212\nLarry,larry@example.com,555-1212\n",
                                 "Name,Email,Phone\nMike,mike@example.com,555-1212\nBob,bob@example.com,555-1212\nJoe,joe@example.com,555-1212\n",
                                 "Name,Email,Phone\nJane,jane@example.com,555-1212\nPaul,paul@example.com,555-1212\nSame,same@example.com,555-1212\n",
                                 "Name,Email,Phone\nBill,bill@example.com,555-1212\nJim,jim@example.com,555-1212\nKevin,kevin@example.com,555-1212\n"]

    @expected_divided_content_malformed_row = ["Name,Email,Phone\nBrian,brian@example.com,555-1212\n",
                                               "Name,Email,Phone\nFoo,foo@example.com,555-1212,foo,bar,foo,baz,foo,bar\nChuck,chuck@example.com,555-1212\n",
                                               "Name,Email,Phone\nDale,dale@example.com,555-1212\nEric,eric@example.com,555-1212\nFrank,frank@example.com,555-1212\n",
                                               "Name,Email,Phone\nGeorge,george@example.com,555-1212\nHenry,henry@example.com,555-1212\nIvan,ivan@example.com,555-1212\n",
                                               "Name,Email,Phone\nJack,jack@example.com,555-1212\nKen,ken@example.com,555-1212\nLarry,larry@example.com,555-1212\n",
                                               "Name,Email,Phone\nMike,mike@example.com,555-1212\nBob,bob@example.com,555-1212\nJoe,joe@example.com,555-1212\n",
                                               "Name,Email,Phone\nJane,jane@example.com,555-1212\nPaul,paul@example.com,555-1212\nSame,same@example.com,555-1212\n",
                                               "Name,Email,Phone\nBill,bill@example.com,555-1212\nJim,jim@example.com,555-1212\nKevin,kevin@example.com,555-1212\n"]

    @expected_divided_content_malformed_last_row = ["Name,Email,Phone\nBrian,brian@example.com,555-1212\nChuck,chuck@example.com,555-1212\n",
                                                    "Name,Email,Phone\nDale,dale@example.com,555-1212\nEric,eric@example.com,555-1212\nFrank,frank@example.com,555-1212\n",
                                                    "Name,Email,Phone\nGeorge,george@example.com,555-1212\nHenry,henry@example.com,555-1212\nIvan,ivan@example.com,555-1212\n",
                                                    "Name,Email,Phone\nJack,jack@example.com,555-1212\nKen,ken@example.com,555-1212\nLarry,larry@example.com,555-1212\n",
                                                    "Name,Email,Phone\nMike,mike@example.com,555-1212\nBob,bob@example.com,555-1212\nJoe,joe@example.com,555-1212\n",
                                                    "Name,Email,Phone\nJane,jane@example.com,555-1212\nPaul,paul@example.com,555-1212\nSame,same@example.com,555-1212\n",
                                                    "Name,Email,Phone\nBill,bill@example.com,555-1212\nJim,jim@example.com,555-1212\nKevin,kevin@example.com,555-1212\n",
                                                    "Name,Email,Phone\nFoo,foo@example.com,555-1212,foo,bar,foo,baz,foo,bar\n"]

    @expected_divided_content_newline_in_field = ["Name,Email,Phone\nBrian,brian@example.com,555-1212\nChuck,chuck\\n@example.com,555-1212\n",
                                                  "Name,Email,Phone\nDale,dale@example.com,555-1212\nEric,eric@example.com,555-1212\nFrank,frank@example.com,555-1212\n",
                                                  "Name,Email,Phone\nGeorge,george@example.com,555-1212\nHenry,henry@example.com,555-1212\nIvan,ivan@example.com,555-1212\n",
                                                  "Name,Email,Phone\nJack,jack@example.com,555-1212\nKen,ken@example.com,555-1212\nLarry,larry@example.com,555-1212\n",
                                                  "Name,Email,Phone\nMike,mike@example.com,555-1212\nBob,bob@example.com,555-1212\nJoe,joe@example.com,555-1212\n",
                                                  "Name,Email,Phone\nJane,jane@example.com,555-1212\nPaul,paul@example.com,555-1212\nSame,same@example.com,555-1212\n",
                                                  "Name,Email,Phone\nBill,bill@example.com,555-1212\nJim,jim@example.com,555-1212\nKevin,kevin@example.com,555-1212\n"]

    @expected_split_content = [{"Name"=>"Brian", "Email"=>"brian@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Chuck", "Email"=>"chuck@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Dale", "Email"=>"dale@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Eric", "Email"=>"eric@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Frank", "Email"=>"frank@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"George", "Email"=>"george@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Henry", "Email"=>"henry@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Ivan", "Email"=>"ivan@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Jack", "Email"=>"jack@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Ken", "Email"=>"ken@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Larry", "Email"=>"larry@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Mike", "Email"=>"mike@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Bob", "Email"=>"bob@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Joe", "Email"=>"joe@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Jane", "Email"=>"jane@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Paul", "Email"=>"paul@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Same", "Email"=>"same@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Bill", "Email"=>"bill@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Jim", "Email"=>"jim@example.com", "Phone"=>"555-1212"},
                               {"Name"=>"Kevin", "Email"=>"kevin@example.com", "Phone"=>"555-1212"}]

    @expected_parsed_content =[{"Email"=>"brian@example.com", "Name"=>"Brian", "Phone"=>"555-1212"},
                               {"Email"=>"chuck@example.com", "Name"=>"Chuck", "Phone"=>"555-1212"},
                               {"Email"=>"dale@example.com", "Name"=>"Dale", "Phone"=>"555-1212"},
                               {"Email"=>"eric@example.com", "Name"=>"Eric", "Phone"=>"555-1212"},
                               {"Email"=>"frank@example.com", "Name"=>"Frank", "Phone"=>"555-1212"},
                               {"Email"=>"george@example.com", "Name"=>"George", "Phone"=>"555-1212"},
                               {"Email"=>"henry@example.com", "Name"=>"Henry", "Phone"=>"555-1212"},
                               {"Email"=>"ivan@example.com", "Name"=>"Ivan", "Phone"=>"555-1212"},
                               {"Email"=>"jack@example.com", "Name"=>"Jack", "Phone"=>"555-1212"},
                               {"Email"=>"ken@example.com", "Name"=>"Ken", "Phone"=>"555-1212"},
                               {"Email"=>"larry@example.com", "Name"=>"Larry", "Phone"=>"555-1212"},
                               {"Email"=>"mike@example.com", "Name"=>"Mike", "Phone"=>"555-1212"},
                               {"Email"=>"bob@example.com", "Name"=>"Bob", "Phone"=>"555-1212"},
                               {"Email"=>"joe@example.com", "Name"=>"Joe", "Phone"=>"555-1212"},
                               {"Email"=>"jane@example.com", "Name"=>"Jane", "Phone"=>"555-1212"},
                               {"Email"=>"paul@example.com", "Name"=>"Paul", "Phone"=>"555-1212"},
                               {"Email"=>"same@example.com", "Name"=>"Same", "Phone"=>"555-1212"},
                               {"Email"=>"bill@example.com", "Name"=>"Bill", "Phone"=>"555-1212"},
                               {"Email"=>"jim@example.com", "Name"=>"Jim", "Phone"=>"555-1212"},
                               {"Email"=>"kevin@example.com", "Name"=>"Kevin", "Phone"=>"555-1212"}]

    @config_store = []
    @config_default = Armagh::Support::CSV::Parser.create_configuration( @config_store, 'def', {} )
    @config_size_100 = Armagh::Support::CSV::Divider.create_configuration( @config_store, 's100', { 'csv_divider' => { 'size_per_part'  => 100 }})
    @config_nonstandard = Armagh::Support::CSV::Parser.create_configuration( @config_store, 'non_standard_rows', { 'csv_parser' => { 'non_standard_rows' => ["^##!!"]}} )
  end

  test "divides source csv into array of multiple csv strings having max size of 'size_per_part' bytes" do
    actual_divided_content = []

    Armagh::Support::CSV.divided_parts(@csv, @config_size_100) do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content, actual_divided_content
    assert_equal false, Armagh::Support::CSV.parts_sizes(actual_divided_content).map(&:size).any? {|x| x > 100}
  end

  test "properly divides source csv when row contains extra values" do
    actual_divided_content = []

    Armagh::Support::CSV.divided_parts(@csv_row_with_extra_values_path, @config_size_100) do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content_malformed_row, actual_divided_content
    assert_equal false, Armagh::Support::CSV.parts_sizes(actual_divided_content).map(&:size).any? {|x| x > 100}
  end

  test "properly divides source csv when row contains extra values on last row" do
    actual_divided_content = []

    Armagh::Support::CSV.divided_parts(@csv_with_extra_values_last_row_path, @config_size_100) do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content_malformed_last_row, actual_divided_content
    assert_equal false, Armagh::Support::CSV.parts_sizes(actual_divided_content).map(&:size).any? {|x| x > 100}
  end

  test "properly divides source csv when row contains newline in one of its fields" do
    actual_divided_content = []

    Armagh::Support::CSV.divided_parts(@csv_with_newline_in_field, @config_size_100) do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content_newline_in_field, actual_divided_content
    assert_equal false, Armagh::Support::CSV.parts_sizes(actual_divided_content).map(&:size).any? {|x| x > 100}
  end

  test "when csv has row with extra values, divided parts match source csv when recombined" do
    expected_combined_content = IO.binread(@csv_row_with_extra_values_path)
    divided_content = []

    Armagh::Support::CSV.divided_parts(@csv_row_with_extra_values_path, @config_size_100) do |part|
      divided_content << part
    end

    assert_equal expected_combined_content, combine_parts(divided_content)
  end

  test "when csv has last row with extra values, divided parts match source csv when recombined" do
    expected_combined_content = IO.binread(@csv_with_extra_values_last_row_path)
    divided_content = []

    Armagh::Support::CSV.divided_parts(@csv_with_extra_values_last_row_path, @config_size_100) do |part|
      divided_content << part
    end

    assert_equal expected_combined_content, combine_parts(divided_content)
  end

  test "when csv is well-formed, divided parts match source csv when recombined" do
    expected_combined_content = IO.binread(@csv)
    divided_content = []

    Armagh::Support::CSV.divided_parts(@csv, @config_size_100) do |part|
      divided_content << part
    end

    assert_equal expected_combined_content, combine_parts(divided_content)
  end

  test "when csv has field with a newline, divided parts match source csv when recombined" do
    expected_combined_content = IO.binread(@csv_with_newline_in_field)
    divided_content = []

    Armagh::Support::CSV.divided_parts(@csv_with_newline_in_field, @config_size_100) do |part|
      divided_content << part
    end

    assert_equal expected_combined_content, combine_parts(divided_content)
  end

  test "dividing returns an error when block isn't passed in" do

    assert_raise(LocalJumpError) {
      Armagh::Support::CSV.divided_parts(@csv, @config_size_100)
    }
  end

  test "splits source file into individual rows" do
    doc = doc_from_fixture(@csv)

    actual_split_content = []

    Armagh::Support::CSV.split_parts(doc, @config_default ) do |row|
      actual_split_content << row
    end

    assert_equal @expected_split_content, actual_split_content
  end

  test "returns an error when csv row is missing a value" do
    doc = doc_from_fixture(@csv_row_with_missing_value_path)

    actual_split_content = []
    actual_errors = []
    expected_split_content = @expected_split_content.dup
    expected_split_content.delete_at(1)

    Armagh::Support::CSV.split_parts(doc, @config_default) do |row, errors|
      actual_split_content << row if errors.empty?
      actual_errors << errors unless errors.empty?
      actual_errors.flatten!
    end

    assert_instance_of Armagh::Support::CSV::Parser::RowMissingValueError, actual_errors.first
  end

  test "returns an error when csv row has extra values" do
    doc = doc_from_fixture(@csv_row_with_extra_values_path)

    actual_split_content = []
    actual_errors = nil

    Armagh::Support::CSV.split_parts(doc, @config_default) do |row, errors|
      actual_split_content << row if errors.empty?
      actual_errors = errors if !errors.empty?
    end

    assert_instance_of Armagh::Support::CSV::Parser::RowWithExtraValuesError, actual_errors.first
  end

  test "splitting returns an error when block isn't passed in" do
    doc = doc_from_fixture(@csv)

    assert_raise(LocalJumpError) {
      Armagh::Support::CSV.split_parts(doc, @config_default)
    }
  end

  test "iterates over each line in the CSV, passing each line to a block if block is given" do
    doc = doc_from_fixture(@csv)

    actual_content = []
    actual_errors = nil

    Armagh::Support::CSV.each_line(doc, @config_default) do |row_hash, errors|
      actual_content << row_hash
      actual_errors = errors
    end

    assert_equal @expected_parsed_content, actual_content
    assert_equal [], actual_errors
  end

  test "iterates over each line in CSV, ignoring non-standard lines before actual CSV header, based on configuration" do
    doc = doc_from_fixture(@csv_with_non_standard_padding_rows)

    actual_content = []
    actual_errors = nil

    Armagh::Support::CSV.each_line(doc, @config_nonstandard) do |row_hash, errors|
      actual_content << row_hash
      actual_errors = errors
    end

    assert_equal @expected_parsed_content, actual_content
    assert_equal [], actual_errors
  end

  test "returns an error when parsing csv with row that's missing a value" do
    doc = doc_from_fixture(@csv_row_with_missing_value_path)

    actual_content = []
    actual_errors = []

    Armagh::Support::CSV.each_line(doc, @config_default) do |row_hash, errors|
      actual_content << row_hash
      actual_errors << errors unless errors.empty?
      actual_errors.flatten!
    end

    assert_instance_of Armagh::Support::CSV::Parser::RowMissingValueError, actual_errors.first
  end

  test "returns an error when parsing csv with row that has an extra value" do
    doc = doc_from_fixture(@csv_row_with_extra_values_path)

    actual_content = []
    actual_errors = []

    Armagh::Support::CSV.each_line(doc, @config_default) do |row_hash, errors|
      actual_content << row_hash
      actual_errors << errors unless errors.empty?
      actual_errors.flatten!
    end

    assert_instance_of Armagh::Support::CSV::Parser::RowWithExtraValuesError, actual_errors.first
  end

  test "parsing returns an error when block isn't passed in" do
    doc = doc_from_fixture(@csv)

    assert_raise(LocalJumpError) {
      Armagh::Support::CSV.each_line(doc, @config_default)
    }
  end
end

