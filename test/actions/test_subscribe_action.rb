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

require_relative '../../lib/armagh/actions/subscribe_action'

class TestSubscribeAction < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    @input_docspec = Armagh::DocSpec.new('InputDocument', Armagh::DocState::PUBLISHED)
    @output_docspec = Armagh::DocSpec.new('OutputDocument', Armagh::DocState::READY)

    @subscribe_action = Armagh::SubscribeAction.new('subscribe', @caller, @logger, {}, {'input_type' => @input_docspec}, {'output_type'=> @output_docspec})
  end

  def test_unimplemented_subscribe
    assert_raise(Armagh::ActionErrors::ActionMethodNotImplemented) {@subscribe_action.subscribe(nil)}
  end

  def test_edit
    yielded_doc = mock
    @caller.expects(:edit_document).with('123', @output_docspec).yields(yielded_doc)

    @subscribe_action.edit('123', 'output_type') do |doc|
      assert_equal yielded_doc, doc
    end
  end

  def test_edit_undefined_type
    assert_raise(Armagh::ActionErrors::DocSpecError) do
      @subscribe_action.edit('123', 'bad_type') {|doc|}
    end
  end

  def test_valid
    assert_true @subscribe_action.valid?
    assert_empty @subscribe_action.validation_errors
  end

  def test_valid_invalid_in_state
    input_docspec = Armagh::DocSpec.new('InputDocument', Armagh::DocState::WORKING)
    subscribe_action = Armagh::SubscribeAction.new('action', @caller, @logger, {}, {'input_type' => input_docspec}, {'output_type'=> @output_docspec})
    assert_false subscribe_action.valid?
    assert_equal({'input_type' => 'Input document state for a SubscribeAction must be published.'}, subscribe_action.validation_errors['input_docspecs'])

    input_docspec = Armagh::DocSpec.new('InputDocument', Armagh::DocState::READY)
    subscribe_action = Armagh::SubscribeAction.new('action', @caller, @logger, {}, {'input_type' => input_docspec}, {'output_type'=> @output_docspec})
    assert_false subscribe_action.valid?
    assert_equal({'input_type' => 'Input document state for a SubscribeAction must be published.'}, subscribe_action.validation_errors['input_docspecs'])
  end

  def test_valid_invalid_out_state
    output_docspec = Armagh::DocSpec.new('OutputDoctype', Armagh::DocState::PUBLISHED)
    subscribe_action = Armagh::SubscribeAction.new('action', @caller, @logger, {}, {'input_type' => @input_docspec}, {'output_type'=> output_docspec})
    assert_false subscribe_action.valid?
    assert_equal({'output_type' => 'Output document state for a SubscribeAction must be ready or working.'}, subscribe_action.validation_errors['output_docspecs'])
  end

  def test_inheritence
    assert_true Armagh::SubscribeAction.respond_to? :define_parameter
    assert_true Armagh::SubscribeAction.respond_to? :defined_parameters

    assert_true Armagh::SubscribeAction.respond_to? :define_input_docspec
    assert_true Armagh::SubscribeAction.respond_to? :defined_input_docspecs
    assert_true Armagh::SubscribeAction.respond_to? :define_output_docspec
    assert_true Armagh::SubscribeAction.respond_to? :defined_output_docspecs

    assert_true @subscribe_action.respond_to? :valid?
    assert_true @subscribe_action.respond_to? :validate
  end
end
