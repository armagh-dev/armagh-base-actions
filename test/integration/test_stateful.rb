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
      define_output_docspec 'output_type', 'action description', default_type: 'OutputDocument', default_state: Armagh::Documents::DocState::READY
    end
  end
end

class TestIntegrationActionStateful < Test::Unit::TestCase

  def self.startup
    MongoSupport.instance.start_mongo
  end

  def self.shutdown
    MongoSupport.instance.stop_mongo
  end
  
  def setup
    MongoSupport.instance.clean_database
    @action_state_store = MongoSupport.instance.client[ 'test_action_state_store' ]
    config_hash = { 
      'action' => { 'name' => 'fred' },
      'collect' => { 'schedule' => '0 * * * *', 'archive' => false },
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_type1', Armagh::Documents::DocState::READY )}
    }
    @logger = mock
    action_config = Armagh::StandardActions::TIASCollect.create_configuration( [], 'fred', config_hash )
    @action = Armagh::StandardActions::TIASCollect.new( self, @logger, action_config, @action_state_store )
  end
  
  def test_new_state_doc
    @action.with_locked_action_state( 10 ) do |state|
      state.content = { 'Yohoho' => 'rum' }
    end
    d = @action_state_store.find( { 'name' => 'fred_state' }).first
    assert_equal 'fred_state', d['name']
    assert_equal ({"Yohoho"=>"rum"}), d['content']
    assert_equal nil, d['locked_by']
    assert_equal nil, d['locked_at']
    assert_equal 'Armagh::Actions::ActionStateDocument', d['type']
  end
  
  def test_new_state_doc_and_reopen
    assert_nothing_raised do
      @action.with_locked_action_state( 10 ) do |state|
        state.content = { 'Yohoho' => 'rum' }
      end
    end
    d = @action_state_store.find( { 'name' => 'fred_state' }).first
    assert_equal 'fred_state', d['name']
    assert_equal ({"Yohoho"=>"rum"}), d['content']
    assert_equal nil, d['locked_by']
    assert_equal nil, d['locked_at']
    assert_equal 'Armagh::Actions::ActionStateDocument', d['type']
    assert_nothing_raised do
      @action.with_locked_action_state( 10 ) do |state|
        assert_equal( { 'Yohoho' => 'rum' }, state.content )
      end
    end
  end
  
  def test_wait_no_timeout
    pid = Process.fork do 
      assert_nothing_raised do
        @action.with_locked_action_state( 10 ) do |state|
          state.content = { 'Yohoho' => 'rum' }
          sleep 15
        end
      end
    end
    sleep 20 
    assert_nothing_raised do
      @action.with_locked_action_state(10) do |state|
        assert_equal( { 'Yohoho' => 'rum' }, state.content )
      end
    end
    pid2, status2 = Process.wait2
    assert_equal pid, pid2
    assert_equal 0, status2.exitstatus
  end

  def test_wait_with_timeout
    pid = Process.fork do
      assert_nothing_raised do
        @action.with_locked_action_state( 10 ) do |state|
          state.content = { 'Yohoho' => 'rum' }
          sleep 15
        end
      end
    end
    sleep 10 
    assert_raises( Armagh::Actions::ActionStateTimeoutError ) do
      @action.with_locked_action_state(1) do |state|
      end
    end
    pid2, status2 = Process.wait2
    assert_equal pid, pid2
    assert_equal 0, status2.exitstatus
  end   
  
  def test_save
    assert_nothing_raised do
      @action.with_locked_action_state( 10 ) do |state|
        state.content[ 'Yohoho' ] = 'rum'
        assert_nothing_raised do
          state.save
        end
        d = @action_state_store.find( { 'name' => 'fred_state' }).first
        assert_equal 'fred_state', d['name']
        assert_equal( {"Yohoho"=>"rum"}, d['content'] )
        assert_not_nil d['locked_by']
        state.content[ 'cheer' ] = 'beer'
        assert_nothing_raised do
          state.save
        end
        d = @action_state_store.find( { 'name' => 'fred_state' }).first
        assert_equal 'fred_state', d['name']
        assert_equal( {"Yohoho"=>"rum","cheer"=>"beer"}, d['content'] )
        assert_not_nil d['locked_by']
      end
    end
    d = @action_state_store.find( { 'name' => 'fred_state' }).first
    assert_equal 'fred_state', d['name']
    assert_equal ({"Yohoho"=>"rum","cheer"=>"beer"}), d['content']
    assert_equal nil, d['locked_by']
    assert_equal nil, d['locked_at']
    assert_equal 'Armagh::Actions::ActionStateDocument', d['type']
  end
end
