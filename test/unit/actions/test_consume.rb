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

require_relative '../../../lib/armagh/actions/consume'

class TestConsume < Test::Unit::TestCase

  def setup
    @caller = mock
    @config_store = []
    @collection = mock
    
    if Object.const_defined?( :SubConsume )
      Object.send( :remove_const, :SubConsume )
    end
    Object.const_set :SubConsume, Class.new( Armagh::Actions::Consume )
    SubConsume.define_default_input_type 'consumed'
    SubConsume.define_output_docspec( 'output_type', 'action description', default_type: 'OutputDocument', default_state: Armagh::Documents::DocState::READY )
    @config = SubConsume.create_configuration( @config_store, 'set', {
      'action' => { 'name' => 'subconsume' }
      })
    
    @consume_action = SubConsume.new( @caller, 'logger_name', @config, @collection )
  end

  def test_unimplemented_consume
    assert_raise(Armagh::Actions::Errors::ActionMethodNotImplemented) {@consume_action.consume(nil)}
  end

  def test_edit
    yielded_doc = mock
    @caller.expects(:edit_document).with('123', @config.output.output_type ).yields(yielded_doc)

    @consume_action.edit('123', 'output_type') do |doc|
      assert_equal yielded_doc, doc
    end
  end

  def test_edit_undefined_type
    assert_raise(Armagh::Documents::Errors::DocSpecError) do
      @consume_action.edit('123', 'bad_type') {|doc|}
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

    @consume_action.edit('output_type') do |doc|
      assert_equal yielded_doc, doc
    end
  end

  def test_valid_invalid_out_spec
    if Object.const_defined?( :SubConsume )
      Object.send( :remove_const, :SubConsume )
    end
    Object.const_set :SubConsume, Class.new( Armagh::Actions::Consume )
    SubConsume.define_default_input_type 'consumed'
    SubConsume.define_output_docspec( 'consumed_doc', 'action description', default_type: 'OutputDocument', default_state: Armagh::Documents::DocState::PUBLISHED )
    e = assert_raises( Configh::ConfigInitError ) {
      config = SubConsume.create_configuration( @config_store, 'inoutstate', {
        'action' => { 'name' => 'subconsume' }
      })
    }
    assert_equal "Unable to create configuration SubConsume inoutstate: Output docspec 'consumed_doc' state must be one of: ready, working.", e.message
  end

  def test_no_out_spec
    Object.send(:remove_const, :SubConsume) if Object.const_defined?(:SubConsume)
    Object.const_set :SubConsume, Class.new( Armagh::Actions::Consume )
    SubConsume.define_default_input_type 'consumed'
    assert_nothing_raised {
      config = SubConsume.create_configuration( @config_store, 'inoutstate', {
        'action' => { 'name' => 'subconsume' }
      })
    }
  end

  def test_no_in_spec
    Object.send(:remove_const, :SubConsume) if Object.const_defined?(:SubConsume)
    Object.const_set :SubConsume, Class.new( Armagh::Actions::Consume )
    e = Configh::ConfigInitError.new('Unable to create configuration SubConsume inoutstate: input docspec: type validation failed: value cannot be nil')
    assert_raise(e) {
      config = SubConsume.create_configuration( @config_store, 'inoutstate', {
        'action' => { 'name' => 'subconsume' }
      })
    }
  end

  def test_invalid_in_spec
    Object.send(:remove_const, :SubConsume) if Object.const_defined?(:SubConsume)
    Object.const_set :SubConsume, Class.new( Armagh::Actions::Consume )
    SubConsume.define_default_input_type 'consumed'
    e = Configh::ConfigInitError.new("Unable to create configuration SubConsume inoutstate: Input docspec 'docspec' state must be published.")
    assert_raise(e) {
      config = SubConsume.create_configuration( @config_store, 'inoutstate', {
        'action' => { 'name' => 'subconsume' },
        'input' => {'docspec' => 'consume:working'}
      })
    }
  end

  def test_valid_out_spec
    SubConsume.define_output_docspec('docspec', 'action description')

    assert_nothing_raised do
      SubConsume.create_configuration([], 'inoutstate', {
        'action' => {'name' => 'subconsume'},
        'input' => {'doctype' => 'randomdoc'},
        'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
      })

      SubConsume.create_configuration([], 'inoutstate', {
        'action' => {'name' => 'subconsume'},
        'input' => {'doctype' => 'randomdoc'},
        'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::WORKING)}
      })
    end
  end

  def test_inheritence
    assert_true SubConsume.respond_to? :define_parameter
    assert_true SubConsume.respond_to? :defined_parameters

    assert_true SubConsume.respond_to? :define_default_input_type
    assert_true SubConsume.respond_to? :define_output_docspec

    assert_true @consume_action.respond_to? :log_debug
    assert_true @consume_action.respond_to? :log_info
    assert_true @consume_action.respond_to? :notify_dev
    assert_true @consume_action.respond_to? :notify_ops
  end
end
