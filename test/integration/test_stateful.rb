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

require_relative '../helpers/coverage_helper'
require_relative '../helpers/mongo_support'

require_relative '../../lib/armagh/actions'
require_relative '../../lib/armagh/actions/stateful'

require 'test/unit'
require 'mocha/test_unit'

require 'mongo'

module Armagh
  module StandardActions
    class TIASCollect < Actions::Collect
    end
  end
end

class TestIntegrationActionStateful < Test::Unit::TestCase

  def self.startup
    puts 'Starting Mongo'
    MongoSupport.instance.start_mongo
  end

  def self.shutdown
    puts 'Stopping Mongo'
    MongoSupport.instance.stop_mongo
  end
  
  def setup
    MongoSupport.instance.clean_database
    @action_state_store = MongoSupport.instance.client[ 'test_action_state_store' ]
    config_hash = { 
      'action' => { 'name' => 'fred' },
      'collect' => { 'schedule' => '0 * * * *', 'archive' => false }
    }
    @logger = mock
    action_config = Armagh::StandardActions::TIASCollect.create_configuration( [], 'fred', config_hash )
    @action = Armagh::StandardActions::TIASCollect.new( self, @logger, action_config, @action_state_store )
  end
  
  def test_new_state_doc
    
    @action.with_locked_action_state( 10 ) do |state|
      state.content = { 'Yohoho' => 'rum' }
    end
    
    d = @action_state_store.find( { '_id' => 'fred_state' }).first
    assert_equal( {"_id"=>"fred_state", "content"=>{"Yohoho"=>"rum"}, "locked_by"=>nil, "locked_at"=>nil, "type"=>"Armagh::Actions::ActionStateDocument"}, d )
  end
  
  def test_new_state_doc_and_reopen
    
    assert_nothing_raised do
      @action.with_locked_action_state( 10 ) do |state|
        state.content = { 'Yohoho' => 'rum' }
      end
    end
    
    d = @action_state_store.find( { '_id' => 'fred_state' }).first
    assert_equal( {"_id"=>"fred_state", "content"=>{"Yohoho"=>"rum"}, "locked_by"=>nil, "locked_at"=>nil, "type"=>"Armagh::Actions::ActionStateDocument"}, d )
    
    assert_nothing_raised do
      @action.with_locked_action_state( 10 ) do |state|
        assert_equal( { 'Yohoho' => 'rum' }, state.content )
      end
    end
  end
  
  def test_wait_but_no_timeout
    
    pid = Thread.new do 
      assert_nothing_raised do
        @action.with_locked_action_state( 10 ) do |state|
          state.content = { 'Yohoho' => 'rum' }
          sleep 20
        end
      end
    end

    sleep 15 
    
    assert_nothing_raised do
      @action.with_locked_action_state(10) do |state|
        assert_equal( { 'Yohoho' => 'rum' }, state.content )
      end
    end
    
  end

  def test_wait_timeout
    
    pid = Thread.new do 
      assert_nothing_raised do
        @action.with_locked_action_state( 10 ) do |state|
          state.content = { 'Yohoho' => 'rum' }
          sleep 60
        end
      end
    end

    sleep 10 
    
    assert_raises( Armagh::Actions::ActionStateTimeoutError ) do
      @action.with_locked_action_state(5) do |state|
      end
    end
    
  end   
  
  def test_save
    
    assert_nothing_raised do
      @action.with_locked_action_state( 10 ) do |state|
        
        state.content[ 'Yohoho' ] = 'rum'
        assert_nothing_raised do
          state.save
        end
        d = @action_state_store.find( { '_id' => 'fred_state' }).first
        assert_equal 'fred_state', d['_id']
        assert_equal( {"Yohoho"=>"rum"}, d['content'] )
        assert_not_nil d['locked_by']
        
        state.content[ 'cheer' ] = 'beer'
        assert_nothing_raised do
          state.save
        end
        d = @action_state_store.find( { '_id' => 'fred_state' }).first
        assert_equal 'fred_state', d['_id']
        assert_equal( {"Yohoho"=>"rum","cheer"=>"beer"}, d['content'] )
        assert_not_nil d['locked_by']
        
      end
    end
    
    d = @action_state_store.find( { '_id' => 'fred_state' }).first
    assert_equal( {"_id"=>"fred_state", "content"=>{"Yohoho"=>"rum","cheer"=>"beer"}, "locked_by"=>nil, "locked_at"=>nil, "type"=>"Armagh::Actions::ActionStateDocument"}, d )
  end
end
