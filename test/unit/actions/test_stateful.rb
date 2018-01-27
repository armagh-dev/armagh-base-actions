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
require_relative '../../../lib/armagh/actions/stateful'
require_relative '../../../lib/armagh/documents/doc_spec'
require_relative '../../../lib/armagh/actions'

require 'test/unit'
require 'mocha/test_unit'

class TestActionStateful < Test::Unit::TestCase
  
  def setup

    @logger = mock
    @caller = mock
    @collection = mock
    if Object.constants.include?( :SubSplit )
      Object.send( :remove_const, :SubSplit )
    end
    Object.const_set "SubSplit", Class.new( Armagh::Actions::Split )

    @config_store = []
    @action_name = 'fred_the_action'
    config = nil
    assert_nothing_raised {
      SubSplit.define_default_input_type 'test_type1'
      config = SubSplit.create_configuration( @config_store, @action_name, {
          'action' => { 'workflow' => 'wf'},
          'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
      } )
      @action = SubSplit.new( @caller, 'logger_name', config )
    }

  end

  def test_with_locked_action_state
    hold = 100
    @caller.expects( :with_locked_action_state).with( @action_name, lock_hold_duration: hold )
    @action.with_locked_action_state( hold )
  end

end
