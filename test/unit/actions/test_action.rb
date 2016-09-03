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

require_relative '../../../lib/armagh/documents/doc_spec'
require_relative '../../../lib/armagh/actions'

class TestAction < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    if Object.constants.include?( :SubSplit )
       Object.send( :remove_const, :SubSplit )
    end
    Object.const_set "SubSplit", Class.new( Armagh::Actions::Split )
    SubSplit.include Configh::Configurable
  end

  def test_default_input_type
    type = 'test_type1'
    config = nil
    assert_nothing_raised { 
      SubSplit.define_default_input_type type
      config = SubSplit.use_static_config_values( { 
        'action' => { 'name' => 'fred_the_action'} }) 
      SubSplit.new( @caller, 'logger_name', config )
    }
    assert_equal type, config.input.docspec.type
  end

  def test_define_output_docspec

    config = nil
    assert_nothing_raised { 
      SubSplit.define_default_input_type 'some_doctype'
      SubSplit.define_output_docspec('test_type1', 'do the hokey pokey')
      SubSplit.define_output_docspec('test_type2', 'and turn yourself around', default_state: Armagh::Documents::DocState::READY, default_type: 'type')
      config = SubSplit.use_static_config_values( { 
        'action' => { 'name' => 'fred_the_action'}, 
        'output' => { 'test_type1' => Armagh::Documents::DocSpec.new( 'dans_type1', Armagh::Documents::DocState::READY )}
      }) 
      SubSplit.new( @caller, 'logger_name', config )
    }
    docspec = config.output.test_type2
    assert docspec.is_a?( Armagh::Documents::DocSpec )
  end

  def test_define_output_docspec_bad_name
    e = assert_raise(Configh::ParameterDefinitionError) {SubSplit.define_output_docspec(nil,nil)}
    assert_equal 'name: value cannot be nil', e.message
    assert_empty SubSplit.defined_parameters.find_all{ |p| p.group == 'output' and p.type == 'docspec' }
  end

  def test_define_output_docspec_bad_default_state
    e = assert_raise(Configh::ParameterDefinitionError) {SubSplit.define_output_docspec('generated_doctype', 'description', default_state: 'invalid')}
    assert_equal "generated_doctype output document spec: Unknown state invalid.  Valid states are WORKING, READY, PUBLISHED, Type must be a non-empty string.", e.message
  end

  def test_valid_bad_type    
    Object.const_set "BadClass", Class.new( Armagh::Actions::Action )
    e = assert_raises( Armagh::Actions::ActionError) { BadClass.new( @caller, 'logger_name', Object.new )}
    assert_equal "Unknown Action Type Actions::Action.  Expected to be a descendant of Armagh::Actions::Split, Armagh::Actions::Consume, Armagh::Actions::Publish, Armagh::Actions::Collect, Armagh::Actions::Divide.", e.message
    
  end
  
  def test_cant_define_collect_input
    if Object.constants.include?( :SubCollect )
       Object.send( :remove_const, :SubCollect )
    end
    Object.const_set "SubCollect", Class.new( Armagh::Actions::Collect )
    SubCollect.include Configh::Configurable
    e = assert_raise( Armagh::Actions::ConfigurationError ) {
      SubCollect.define_default_input_type 'blech'
    }
    assert_equal "You cannot define default input types for collectors", e.message
  end
end
