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

require_relative '../../../lib/armagh/documents/doc_spec'
require_relative '../../../lib/armagh/actions'

class TestAction < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    @collection = mock
    if Object.constants.include?( :SubSplit )
       Object.send( :remove_const, :SubSplit )
    end
    Object.const_set "SubSplit", Class.new( Armagh::Actions::Split )
    @config_store = []
  end

  def test_config_action_group
    action_name = 'fred_the_action'
    config = nil
    assert_nothing_raised {
      SubSplit.define_default_input_type 'test_type1'
      config = SubSplit.create_configuration( @config_store, action_name, {
        'action' => { 'workflow' => 'wf'},
        'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
      } )
      SubSplit.new( @caller, 'logger_name', config )
    }
    assert_equal action_name, config.action.name
    assert_true config.action.active
  end

  def test_default_input_type
    type = 'test_type1'
    config = nil
    assert_nothing_raised {
      SubSplit.define_default_input_type type
      SubSplit.define_output_docspec('output_type', 'action description', default_type: 'OutputDocument', default_state: Armagh::Documents::DocState::READY)
      config = SubSplit.create_configuration( @config_store, 'defintype', {
        'action' => { 'name' => 'fred_the_action', 'workflow' => 'wf'},
        'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}})
      SubSplit.new( @caller, 'logger_name', config )
    }
    assert_equal type, config.input.docspec.type
  end

  def test_define_output_docspec

    config = nil
    assert_nothing_raised {
      SubSplit.define_default_input_type 'some_doctype'
      SubSplit.define_output_docspec('type2', 'and turn yourself around', default_state: Armagh::Documents::DocState::READY, default_type: 'type')
      config = SubSplit.create_configuration( @config_store, 'defoutds', {
        'action' => { 'name' => 'fred_the_action', 'workflow' => 'wf'},
        'output' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_type1', Armagh::Documents::DocState::READY ),
                      'type2' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
      })
      SubSplit.new( @caller, 'logger_name', config )
    }
    docspec = config.output.type2
    assert docspec.is_a?( Armagh::Documents::DocSpec )
  end

  def test_define_output_docspec_bad_name
    e = assert_raise(Configh::ParameterDefinitionError) {SubSplit.define_output_docspec(nil,nil)}
    assert_equal 'name: string is empty or nil', e.message
    assert_empty SubSplit.defined_parameters.find_all{ |p| p.group == 'output' && p.type == 'docspec' && p.name != 'docspec' }
  end

  def test_define_output_docspec_bad_default_state
    e = assert_raise(Configh::ParameterDefinitionError) {SubSplit.define_output_docspec('generated_doctype', 'description', default_state: 'invalid')}
    assert_equal 'generated_doctype output document spec: Unknown state invalid.  Valid states are PUBLISHED, READY, WORKING, Type must be a non-empty string.', e.message
  end

  def test_valid_bad_type
    Object.const_set "BadClass", Class.new( Armagh::Actions::Action )
    e = assert_raises( Armagh::Actions::ActionError) { BadClass.new( @caller, 'logger_name', Object.new )}
    assert_equal 'Unknown Action Type BadClass.  Expected to be a descendant of Armagh::Actions::Split, Armagh::Actions::Consume, Armagh::Actions::Publish, Armagh::Actions::Collect, Armagh::Actions::Divide.', e.message

  end

  def test_cant_define_collect_input
    if Object.constants.include?( :SubCollect )
       Object.send( :remove_const, :SubCollect )
    end
    Object.const_set "SubCollect", Class.new( Armagh::Actions::Collect )
    e = assert_raise( Armagh::Actions::ConfigurationError ) {
      SubCollect.define_default_input_type 'blech'
    }
    assert_equal 'You cannot define default input types for collectors', e.message
  end

  def test_you_have_your_stuff_i_have_mine

    SubSplit.define_output_docspec 'subsplit_ds1', 'desc'
    SubSplit.define_output_docspec 'subsplit_ds2', 'desc'

    Object.const_set "SubSplit2", Class.new( Armagh::Actions::Split )
    SubSplit2.define_output_docspec 'subsplit2_ds1', 'desc'

    assert_equal %w(docspec subsplit_ds1 subsplit_ds2), SubSplit.defined_parameters.find_all{ |p| p.group == 'output' }.collect{ |p| p.name }.sort
    assert_equal %w(docspec subsplit2_ds1), SubSplit2.defined_parameters.find_all{ |p| p.group == 'output' }.collect{ |p| p.name }.sort
  end

  def test_random_id
    SubSplit.define_default_input_type 'some_doctype'
    SubSplit.define_output_docspec('type2', 'and turn yourself around', default_state: Armagh::Documents::DocState::READY, default_type: 'type')
    config = SubSplit.create_configuration( @config_store, 'defoutds', {
      'action' => { 'name' => 'fred_the_action', 'workflow' => 'wf'},
      'output' => {
        'docspec' => Armagh::Documents::DocSpec.new( 'default_type', Armagh::Documents::DocState::READY ),
        'type2' => Armagh::Documents::DocSpec.new( 'dans_type2', Armagh::Documents::DocState::READY )
      }
    })
    split = SubSplit.new( @caller, 'logger_name', config )
    id = split.random_id
    assert_equal(id, id.strip)
    assert_match(/^\w{#{Armagh::Support::Random::RANDOM_ID_LENGTH - 5},#{Armagh::Support::Random::RANDOM_ID_LENGTH}}$/, id)
  end

  def test_create_config_with_bad_value_type
    action_name = 'fred_the_action'
    config = nil
    assert_raise(Armagh::Actions::InvalidArgumentError) {
      SubSplit.define_default_input_type 'test_type1'
      config = SubSplit.create_configuration( @config_store, action_name, nil )
      SubSplit.new( @caller, 'logger_name', config )
    }
  end

  def test_create_config_with_bad_name_type
    config = nil
    assert_raise(Armagh::Actions::InvalidArgumentError) {
      SubSplit.define_default_input_type 'test_type1'
      config = SubSplit.create_configuration( @config_store, nil, {} )
      SubSplit.new( @caller, 'logger_name', config )
    }
  end

  def test_workflow_parameter
    config = nil
    assert_nothing_raised do
      config = SubSplit.create_configuration( @config_store, 'workflow_test', {
        'action' => {
          'name' => 'workflow_test_action',
          'workflow' => 'MyWorkflow'
        },
        'input' => { 'docspec' => Armagh::Documents::DocSpec.new('docspec', Armagh::Documents::DocState::READY) },
        'output' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_type1', Armagh::Documents::DocState::READY )}
      })
    end
    assert_equal 'MyWorkflow', config.get.dig('values', 'action', 'workflow')
  end

  def test_default_description
    assert_equal 'No description available.', SubSplit.description
  end
end
