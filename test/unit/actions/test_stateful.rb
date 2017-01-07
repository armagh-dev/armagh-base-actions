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

require_relative '../../../lib/armagh/actions/stateful'

class TestActionStateful < Test::Unit::TestCase
  
  def setup
    @config_coll = mock
  end
  
  def find_or_create_new_expects
    
    @config_coll
      .expects( :find_one_and_update )
      .with(){ |filter,update|
        filter['_id'] == 'fred_state' && 
        filter['locked_by'] == nil &&
        update['$set']['locked_by'] == 123 &&
        update['$set'].has_key?('locked_at')
      }.returns( 
        nil, 
        { '_id' => 'fred_state', 'type' => 'Armagh::Actions::ActionStateDocument', 'locked_by' => 123, 'locked_at' => Time.now, 'content' => {}} 
      )
    
    @config_coll
      .expects( :insert_one )
      .with( ){ |h|
        h['_id']  == 'fred_state' &&
        h['type'] == 'Armagh::Actions::ActionStateDocument' &&
        h[ 'locked_by' ] == 123 &&
        h.has_key?( 'locked_at') &&
        h['content' ] == {} 
      }.returns( 'dont_use_me')
      
  end
  
  def test_find_or_create_new
    find_or_create_new_expects
    d = Armagh::Actions::ActionStateDocument.find_or_create( @config_coll, 'fred', 123, 10 )
    assert_equal( {}, d.content)
  end
  
  def test_save_and_unlock_good
    find_or_create_new_expects
    @config_coll
      .expects( :find_one_and_update )
      .with(){ |filter,update|
        filter['_id'] == 'fred_state' && 
        filter['locked_by'] == 123 &&
        update['$set']['locked_by'] == nil 
      }
    
    d = Armagh::Actions::ActionStateDocument.find_or_create( @config_coll, 'fred', 123, 10 )  
    assert_nothing_raised do
      d.save_and_unlock
    end
    assert_equal nil, d.locked_by
    
  end
  
end
