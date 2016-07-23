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

require_relative '../coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../lib/armagh/support/csv'

class TestCsv < Test::Unit::TestCase
  include Armagh::Support::CSV

  def setup
    @csv = "./test/fixtures/test.csv"
    @csv_with_extra_values_path = "./test/fixtures/row_with_extra_values.csv"
    @csv_with_extra_values_last_row_path = "./test/fixtures/extra_values_on_last_row.csv"
    @csv_with_newline_in_field = "./test/fixtures/newline_in_field.csv"

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
  end

  test "divides source csv into array of multiple csv strings having max size of 'size_per_part' bytes" do
    actual_divided_content = []

    Armagh::Support::CSV.divided_parts(source: @csv, size_per_part: 100, col_sep: ',', row_sep: :auto, quote_char: '"') do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content, actual_divided_content
    assert_equal false, Armagh::Support::CSV.parts_sizes(actual_divided_content).any? {|x| x > 100}
  end

  test "properly divides source csv when row contains extra values" do
    actual_divided_content = []

    Armagh::Support::CSV.divided_parts(source: @csv_with_extra_values_path, size_per_part: 100, col_sep: ',', row_sep: :auto, quote_char: '"') do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content_malformed_row, actual_divided_content
    assert_equal false, Armagh::Support::CSV.parts_sizes(actual_divided_content).any? {|x| x > 100}
  end

  test "properly divides source csv when row contains extra values on last row" do
    actual_divided_content = []

    Armagh::Support::CSV.divided_parts(source: @csv_with_extra_values_last_row_path, size_per_part: 100, col_sep: ',', row_sep: :auto, quote_char: '"') do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content_malformed_last_row, actual_divided_content
    assert_equal false, Armagh::Support::CSV.parts_sizes(actual_divided_content).any? {|x| x > 100}
  end

  test "properly divides source csv when row contains newline in one of its fields" do
    actual_divided_content = []

    Armagh::Support::CSV.divided_parts(source: @csv_with_newline_in_field, size_per_part: 100, col_sep: ',', row_sep: :auto, quote_char: '"') do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content_newline_in_field, actual_divided_content
    assert_equal false, Armagh::Support::CSV.parts_sizes(actual_divided_content).any? {|x| x > 100}
  end

  test "when csv has row with extra values, divided parts match source csv when recombined" do
    expected_combined_content = IO.binread(@csv_with_extra_values_path)
    divided_content = []

    Armagh::Support::CSV.divided_parts(source: @csv_with_extra_values_path, size_per_part: 100, col_sep: ',', row_sep: :auto, quote_char: '"') do |part|
      divided_content << part
    end

    assert_equal expected_combined_content, Armagh::Support::CSV.combine_parts(divided_content)
  end

  test "when csv has last row with extra values, divided parts match source csv when recombined" do
    expected_combined_content = IO.binread(@csv_with_extra_values_last_row_path)
    divided_content = []

    Armagh::Support::CSV.divided_parts(source: @csv_with_extra_values_last_row_path, size_per_part: 100, col_sep: ',', row_sep: :auto, quote_char: '"') do |part|
      divided_content << part
    end

    assert_equal expected_combined_content, Armagh::Support::CSV.combine_parts(divided_content)
  end

  test "when csv is well-formed, divided parts match source csv when recombined" do
    expected_combined_content = IO.binread(@csv)
    divided_content = []

    Armagh::Support::CSV.divided_parts(source: @csv, size_per_part: 100, col_sep: ',', row_sep: :auto, quote_char: '"') do |part|
      divided_content << part
    end

    assert_equal expected_combined_content, Armagh::Support::CSV.combine_parts(divided_content)
  end

  test "when csv has field with a newline, divided parts match source csv when recombined" do
    expected_combined_content = IO.binread(@csv_with_newline_in_field)
    divided_content = []

    Armagh::Support::CSV.divided_parts(source: @csv_with_newline_in_field, size_per_part: 100, col_sep: ',', row_sep: :auto, quote_char: '"') do |part|
      divided_content << part
    end

    assert_equal expected_combined_content, Armagh::Support::CSV.combine_parts(divided_content)
  end
end
