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

require_relative '../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../lib/armagh/support/json'
require_relative '../../helpers/json_test_helpers'


class TestJSON < Test::Unit::TestCase
  include JSONTestHelpers
  include Armagh::Support::JSON

  def setup
    @fixtures_path = File.join(__dir__, '..', '..', 'fixtures', 'json')
    @default_json = File.join @fixtures_path, 'test.json'
    @expected_content_path = File.join(@fixtures_path, 'expected_output')
    @expected_divided_content = load_expected_content(File.join(@expected_content_path, 'expected_divided_content.yml'))

    @footer_too_large_json = File.join @fixtures_path, 'test_footer_too_large.json'

    @collected_doc  = mock('collected_document')

    default_config_params = { 'json_divider' => {
                                'size_per_part'  => 300,
                                'divide_target' => 'employees'
                              }
                            }
    @config_store = []
    @default_config  = Armagh::Support::JSON::Divider.create_configuration( @config_store, 'default_config', default_config_params)
    @config_size_200 = Armagh::Support::JSON::Divider.create_configuration( @config_store, 's200', { 'json_divider' => { 'size_per_part' => 200, 'divide_target' => 'employees' } })
    @config_size_120 = Armagh::Support::JSON::Divider.create_configuration( @config_store, 's120', { 'json_divider' => { 'size_per_part' => 120, 'divide_target' => 'employees' } })
    @config_size_10  = Armagh::Support::JSON::Divider.create_configuration( @config_store, 's10',  { 'json_divider' => { 'size_per_part' => 10,  'divide_target' => 'employees' } })
  end

  def test_dividing_returns_an_error_when_block_is_not_passed_in
    @collected_doc.expects(:collected_file).at_least_once.returns(@default_json)

    assert_raise(LocalJumpError) {
      Armagh::Support::JSON.divided_parts(@collected_doc, @default_config)
    }
  end

  def test_returns_an_error_when_size_per_part_is_smaller_than_largest_divided_part
    @collected_doc.expects(:collected_file).at_least_once.returns(@default_json)
    divided_content = []

    assert_raise JSONDivider::SizePerPartTooSmallError do
      Armagh::Support::JSON.divided_parts(@collected_doc, @config_size_200) do |part|
        divided_content << part
      end
    end
  end

  def test_returns_an_error_when_divide_target_not_found_in_first_chunk
    divided_content = []
    @collected_doc.expects(:collected_file).at_least_once.returns(@default_json)

    assert_raise JSONDivider::DivideTargetNotFoundInFirstChunkError do
      Armagh::Support::JSON.divided_parts(@collected_doc, @config_size_10) do |part|
        divided_content << part
      end
    end
  end

  def test_returns_an_error_when_footer_is_too_large
    divided_content = []
    @collected_doc.expects(:collected_file).at_least_once.returns(@footer_too_large_json)

    JSONDivider.any_instance.stubs(:footer_too_large?).returns(true)

    assert_raise JSONDivider::SizeError do
      Armagh::Support::JSON.divided_parts(@collected_doc, @config_size_120) do |part, errors|
        divided_content << part
        divided_errors  << errors unless errors.empty?
      end
    end
  end

  def test_returns_an_error_when_sum_of_header_size_plus_footer_size_is_too_large
    divided_content = []
    @collected_doc.expects(:collected_file).at_least_once.returns(@default_json)

    JSONDivider.any_instance.stubs(:header_footer_too_large?).returns(true)

    assert_raise JSONDivider::SizeError do
      Armagh::Support::JSON.divided_parts(@collected_doc, @default_config) do |part, errors|
        divided_content << part
        divided_errors  << errors unless errors.empty?
      end
    end
  end

end

