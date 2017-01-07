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

require_relative '../../../lib/armagh/actions/split'

class TestSplit < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    @collection = mock
    if Object.const_defined?( :SubSplit )
      Object.send( :remove_const, :SubSplit )
    end
    Object.const_set :SubSplit, Class.new( Armagh::Actions::Split )
    SubSplit.define_default_input_type 'fred'
    SubSplit.define_output_docspec( 'output_type', 'action description', default_type: 'OutputDocument', default_state: Armagh::Documents::DocState::READY )
    @config_store = []
    @config = SubSplit.create_configuration( @config_store, 'set', {
      'action' => { 'name' => 'mysubcollect' }
      })
    @split_action = Armagh::Actions::Split.new( @caller, 'logger_name', @config, @collection)
  end

  def test_unimplemented_split
    assert_raise(Armagh::Actions::Errors::ActionMethodNotImplemented) {@split_action.split(nil)}
  end

  def test_edit
    yielded_doc = mock
    @caller.expects(:edit_document).with('123', @config.output.output_type).yields(yielded_doc)

    @split_action.edit('123', 'output_type') do |doc|
      assert_equal yielded_doc, doc
    end
  end

  def test_edit_undefined_type
    assert_raise(Armagh::Documents::Errors::DocSpecError) do
      @split_action.edit('123', 'bad_type') {|doc|}
    end
  end

  def test_edit_no_id
    yielded_doc = mock
    @caller.expects(:edit_document).with do |id, type|
      assert_not_nil id
      assert_not_empty id
      assert_equal(@config.output.output_type, type)
      true
    end.yields(yielded_doc)

    @split_action.edit('output_type') do |doc|
      assert_equal yielded_doc, doc
    end
  end

  def test_validate_invalid_out_state
    if Object.const_defined?( :SubSplit )
      Object.send( :remove_const, :SubSplit )
    end
    Object.const_set :SubSplit, Class.new( Armagh::Actions::Split )
    SubSplit.define_default_input_type 'fred'
    SubSplit.define_output_docspec( 'output_type', 'action description', default_type: 'OutputDocument', default_state: Armagh::Documents::DocState::PUBLISHED )
    e = assert_raises( Configh::ConfigInitError ) {
      config = SubSplit.create_configuration( @config_store, 'vios', {
        'action' => { 'name' => 'mysubcollect' }
      })
    }
    assert_equal('Unable to create configuration SubSplit vios: Output docspec \'output_type\' state must be one of: ready, working.', e.message )
  end

  def test_inheritence
    assert_true SubSplit.respond_to? :define_parameter
    assert_true SubSplit.respond_to? :defined_parameters

    assert_true SubSplit.respond_to? :define_default_input_type
    assert_true SubSplit.respond_to? :define_output_docspec
    assert_true SubSplit.respond_to? :defined_output_docspecs

    assert_true @split_action.respond_to? :log_debug
    assert_true @split_action.respond_to? :log_info
    assert_true @split_action.respond_to? :notify_dev
    assert_true @split_action.respond_to? :notify_ops
  end
end
