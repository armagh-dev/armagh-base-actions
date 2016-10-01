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

require_relative '../helpers/coverage_helper'

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

  class << self
    
    def startup
      begin
        try_start_mongo
        try_connect
        @@collection = @@connection[ 'config' ]
        @@collection.drop
      rescue
        puts "unable to start mongo"
        exit
      end
    end
    
    def try_start_mongo
      @@pid = nil
      psline = `ps -ef | grep mongod | grep -v grep`
      if psline.empty?
        puts "trying to start mongod..."
        @@pid = spawn 'mongod 1>/dev/null 2>&1'
        sleep 5
      else 
        puts "mongod was running at entry.  will be left running"
        return      
      end
      Process.detach @@pid
      raise if `ps -ef | grep mongod | grep -v grep`.empty?
      puts "mongod successfully started."
      
    end
  
    def try_connect
      Mongo::Logger.logger.level = ::Logger::FATAL
      @@connection = Mongo::Client.new( 
        [ '127.0.0.1:27017' ], 
        :database=>'test_integ_mongo_based_config', 
        :server_selection_timeout => 5,
        :connect_timeout => 5
      )
      @@connection.collections
    end
    
    def shutdown
      if @@pid
        puts "\nshutting down mongod"
        `kill \`pgrep mongod\``
      end
    end
  end


  def setup
    @@collection.drop    
    config_hash = { 
      'action' => { 'name' => 'fred' },
      'collect' => { 'schedule' => '0 * * * *'}
    }
    @logger = mock
    action_config = Armagh::StandardActions::TIASCollect.create_configuration( [], 'fred', config_hash )
    @action = Armagh::StandardActions::TIASCollect.new( self, @logger, action_config, @@collection )
  end
  
  def test_new_state_doc
    
    @action.with_locked_action_state( 10 ) do |state|
      state.content = { 'Yohoho' => 'rum' }
    end
    
    d = @@collection.find( { '_id' => 'fred_state' }).first
    assert_equal( {"_id"=>"fred_state", "content"=>{"Yohoho"=>"rum"}, "locked_by"=>nil, "locked_at"=>nil, "type"=>"Armagh::Actions::ActionStateDocument"}, d )
  end
  
  def test_new_state_doc_and_reopen
    
    assert_nothing_raised do
      @action.with_locked_action_state( 10 ) do |state|
        state.content = { 'Yohoho' => 'rum' }
      end
    end
    
    d = @@collection.find( { '_id' => 'fred_state' }).first
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
        d = @@collection.find( { '_id' => 'fred_state' }).first
        assert_equal 'fred_state', d['_id']
        assert_equal( {"Yohoho"=>"rum"}, d['content'] )
        assert_not_nil d['locked_by']
        
        state.content[ 'cheer' ] = 'beer'
        assert_nothing_raised do
          state.save
        end
        d = @@collection.find( { '_id' => 'fred_state' }).first
        assert_equal 'fred_state', d['_id']
        assert_equal( {"Yohoho"=>"rum","cheer"=>"beer"}, d['content'] )
        assert_not_nil d['locked_by']
        
      end
    end
    
    d = @@collection.find( { '_id' => 'fred_state' }).first
    assert_equal( {"_id"=>"fred_state", "content"=>{"Yohoho"=>"rum","cheer"=>"beer"}, "locked_by"=>nil, "locked_at"=>nil, "type"=>"Armagh::Actions::ActionStateDocument"}, d )
  end
end
