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

require_relative '../../../lib/armagh/actions/consume'

class TestConsume < Test::Unit::TestCase

  def setup
    @caller = mock
    @output_docspec = Armagh::Documents::DocSpec.new('OutputDocument', Armagh::Documents::DocState::READY)

    @consume_action = Armagh::Actions::Consume.new('consume', @caller, 'logger_name', {}, {'output_type'=> @output_docspec})
  end

  def test_unimplemented_consume
    assert_raise(Armagh::Actions::Errors::ActionMethodNotImplemented) {@consume_action.consume(nil)}
  end

  def test_edit
    yielded_doc = mock
    @caller.expects(:edit_document).with('123', @output_docspec).yields(yielded_doc)

    @consume_action.edit('123', 'output_type') do |doc|
      assert_equal yielded_doc, doc
    end
  end

  def test_edit_undefined_type
    assert_raise(Armagh::Documents::Errors::DocSpecError) do
      @consume_action.edit('123', 'bad_type') {|doc|}
    end
  end

  def test_valid
    assert_equal({'errors' => [], 'valid' => true, 'warnings' => []}, @consume_action.validate)
  end

  def test_valid_invalid_out_state
    output_docspec = Armagh::Documents::DocSpec.new('OutputDoctype', Armagh::Documents::DocState::PUBLISHED)
    consume_action = Armagh::Actions::Consume.new('action', @caller, 'logger_name', {}, {'output_type'=> output_docspec})

    valid = consume_action.validate
    assert_false valid['valid']
    assert_equal(['Output docspec \'output_type\' state must be one of: ["ready", "working"].'], valid['errors'])
  end

  def test_inheritence
    assert_true Armagh::Actions::Consume.respond_to? :define_parameter
    assert_true Armagh::Actions::Consume.respond_to? :defined_parameters

    assert_true Armagh::Actions::Consume.respond_to? :define_default_input_type
    assert_true Armagh::Actions::Consume.respond_to? :defined_default_input_type
    assert_true Armagh::Actions::Consume.respond_to? :define_output_docspec
    assert_true Armagh::Actions::Consume.respond_to? :defined_output_docspecs

    assert_true @consume_action.respond_to? :validate
    assert_true @consume_action.respond_to? :log_debug
    assert_true @consume_action.respond_to? :log_info
    assert_true @consume_action.respond_to? :notify_dev
    assert_true @consume_action.respond_to? :notify_ops
  end
end
