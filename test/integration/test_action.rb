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

require 'configh'
require 'mongo'

require_relative '../helpers/coverage_helper'
require_relative '../helpers/mongo_support'
require_relative '../../lib/armagh/actions'

require 'test/unit'
require 'mocha/test_unit'

  
class TestIntegrationAction < Test::Unit::TestCase

  def self.startup
    puts 'Starting Mongo'
    MongoSupport.instance.start_mongo
  end

  def self.shutdown
    puts 'Stopping Mongo'
    MongoSupport.instance.stop_mongo
  end
  
  def setup
    @logger = mock
    @caller = mock
    if Object.constants.include?( :SubSplit )
       Object.send( :remove_const, :SubSplit )
    end
    Object.const_set "SubSplit", Class.new( Armagh::Actions::Split )
    MongoSupport.instance.clean_database
    @config_store = MongoSupport.instance.client[ 'test_config_store' ]
    @action_state_store = @config_store
  end
  
  def test_config_action_group
    action_name = 'fred_the_action'
    config = nil
    assert_nothing_raised { 
      SubSplit.define_default_input_type 'test_type1'
      config = SubSplit.create_configuration( @config_store, action_name, {} )
      SubSplit.new( @caller, 'logger_name', config, @action_state_store )
    }
    assert_equal action_name, config.action.name
    assert_true config.action.active
  end

  def test_default_input_type
    type = 'test_type1'
    config = nil
    assert_nothing_raised { 
      SubSplit.define_default_input_type type
      config = SubSplit.create_configuration( @config_store, 'defintype', { 
        'action' => { 'name' => 'fred_the_action'} }) 
      SubSplit.new( @caller, 'logger_name', config, @action_state_store )
    }
    assert_equal type, config.input.docspec.type
  end

  def test_define_output_docspec

    config = nil
    assert_nothing_raised { 
      SubSplit.define_default_input_type 'some_doctype'
      SubSplit.define_output_docspec('test_type1', 'do the hokey pokey')
      SubSplit.define_output_docspec('test_type2', 'and turn yourself around', default_state: Armagh::Documents::DocState::READY, default_type: 'type')
      config = SubSplit.create_configuration( @config_store, 'defoutds', { 
        'action' => { 'name' => 'fred_the_action'}, 
        'output' => { 'test_type1' => Armagh::Documents::DocSpec.new( 'dans_type1', Armagh::Documents::DocState::READY )}
      }) 
      SubSplit.new( @caller, 'logger_name', config, @action_state_store )
    }
    docspec = config.output.test_type2
    assert docspec.is_a?( Armagh::Documents::DocSpec )
  end

  def test_define_output_docspec_bad_name
    e = assert_raise(Configh::ParameterDefinitionError) {SubSplit.define_output_docspec(nil,nil)}
    assert_equal 'name: string is empty or nil', e.message
    assert_empty SubSplit.defined_parameters.find_all{ |p| p.group == 'output' and p.type == 'docspec' }
  end

  def test_define_output_docspec_bad_default_state
    e = assert_raise(Configh::ParameterDefinitionError) {SubSplit.define_output_docspec('generated_doctype', 'description', default_state: 'invalid')}
    assert_equal "generated_doctype output document spec: Unknown state invalid.  Valid states are WORKING, READY, PUBLISHED, Type must be a non-empty string.", e.message
  end

  def test_valid_bad_type    
    Object.const_set "BadClass", Class.new( Armagh::Actions::Action )
    e = assert_raises( Armagh::Actions::ActionError) { BadClass.new( @caller, 'logger_name', Object.new, @action_state_store )}
    assert_equal "Unknown Action Type Actions::Action.  Expected to be a descendant of Armagh::Actions::Split, Armagh::Actions::Consume, Armagh::Actions::Publish, Armagh::Actions::Collect, Armagh::Actions::Divide.", e.message
    
  end
  
  def test_cant_define_collect_input
    if Object.constants.include?( :SubCollect )
       Object.send( :remove_const, :SubCollect )
    end
    Object.const_set "SubCollect", Class.new( Armagh::Actions::Collect )
    e = assert_raise( Armagh::Actions::ConfigurationError ) {
      SubCollect.define_default_input_type 'blech'
    }
    assert_equal "You cannot define default input types for collectors", e.message
  end
  
  def test_you_have_your_stuff_i_have_mine
    
    SubSplit.define_output_docspec 'subsplit_ds1', 'desc'
    SubSplit.define_output_docspec 'subsplit_ds2', 'desc'
    
    Object.const_set "SubSplit2", Class.new( Armagh::Actions::Split )
    SubSplit2.define_output_docspec 'subsplit2_ds1', 'desc'
    
    assert_equal [ 'subsplit_ds1', 'subsplit_ds2' ], SubSplit.defined_parameters.find_all{ |p| p.group == 'output' }.collect{ |p| p.name }.sort
    assert_equal [ 'subsplit2_ds1' ], SubSplit2.defined_parameters.find_all{ |p| p.group == 'output' }.collect{ |p| p.name }.sort
  end
    
  def test_serialization
    
    config = nil
    assert_nothing_raised { 
      SubSplit.define_default_input_type 'some_doctype'
      SubSplit.define_output_docspec('test_type1', 'do the hokey pokey')
      SubSplit.define_output_docspec('test_type2', 'and turn yourself around', default_state: Armagh::Documents::DocState::READY, default_type: 'type')
      SubSplit.define_parameter name: 'count', type: 'integer', required: true, default: 6, group: 'grp', description: 'desc'
      config = SubSplit.create_configuration( @config_store, 'defaultds', { 
        'action' => { 'name' => 'fred_the_action'}, 
        'output' => { 'test_type1' => Armagh::Documents::DocSpec.new( 'dans_type1', Armagh::Documents::DocState::READY )}
      }) 
      SubSplit.new( @caller, 'logger_name', config, @action_state_store )
    }
    docspec = config.output.test_type2
    assert docspec.is_a?( Armagh::Documents::DocSpec )
    
    stored_config = SubSplit.find_configuration( @config_store, 'defaultds' )
    docspec = stored_config.output.test_type2
    assert docspec.is_a?( Armagh::Documents::DocSpec )
    assert_equal 'type', docspec.type
    assert_equal 'ready', docspec.state
  end
end
