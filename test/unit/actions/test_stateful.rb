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
require_relative '../../../lib/armagh/actions/stateful'

require 'test/unit'
require 'mocha/test_unit'

class TestActionStateful < Test::Unit::TestCase
  
  def setup
    @config_coll = mock
    @find_results = mock
  end
  
  def expect_find_returns_nil
    @config_coll
      .expects(:find)
      .returns(
        @find_results
      )
    @find_results
      .expects(:limit).with(1).returns([nil])
  end

  def expect_find_returns_locked_doc
    @config_coll
      .expects(:find)
      .returns(
        @find_results
      )
    @find_results
      .expects(:limit)
      .with(1)
      .returns(
        [ {'name' => 'fred_state', 'type' => 'Armagh::Actions::ActionStateDocument', 'locked_by' => 123, 'locked_at' => Time.now, 'content' => {}} ]
      )
  end

  def test_find_or_create_doc_locked_by_current_pid
    expect_find_returns_locked_doc
    @config_coll.expects(:insert_one).never
    e = assert_raise(Armagh::Actions::ActionStateError) do
      d = Armagh::Actions::ActionStateDocument.find_or_create(@config_coll, 'fred', 123, 10)
    end
    assert_equal 'Document is already locked by the current process ID', e.message
  end

  def test_find_or_create_new_doc_lock_success
    expect_find_returns_nil
    @config_coll
      .expects(:find_one_and_update)
      .returns( 
        { 'name' => 'fred_state', 'type' => 'Armagh::Actions::ActionStateDocument', 'locked_by' => 123, 'locked_at' => Time.now, 'content' => {} } 
      )
    assert_nothing_raised do
      d = Armagh::Actions::ActionStateDocument.find_or_create(@config_coll, 'fred', 123, 10)
      assert_equal({}, d.content)
    end
  end

  def test_find_or_create_new_doc_lock_fails_try_again_success
    expect_find_returns_nil
    @config_coll
      .expects(:find_one_and_update)
      .times(3)
      .returns( 
        { 'name' => 'fred_state', 'type' => 'Armagh::Actions::ActionStateDocument', 'locked_by' => nil, 'locked_at' => nil, 'content' => {} } ,
        nil, 
        { 'name' => 'fred_state', 'type' => 'Armagh::Actions::ActionStateDocument', 'locked_by' => 123, 'locked_at' => Time.now, 'content' => {} } 
      )
    assert_nothing_raised do
      d = Armagh::Actions::ActionStateDocument.find_or_create(@config_coll, 'fred', 123, 10)
      assert_equal({}, d.content)
    end
  end

  def test_find_or_create_new_doc_lock_fails_try_again_timeout
    expect_find_returns_nil
    @config_coll
      .expects(:find_one_and_update)
      .returns( 
        { 'name' => 'fred_state', 'type' => 'Armagh::Actions::ActionStateDocument', 'locked_by' => nil, 'locked_at' => nil, 'content' => {} } 
      )
    Timeout.stubs(:timeout).raises(Armagh::Actions::ActionStateTimeoutError)
    e = assert_raise(Armagh::Actions::ActionStateTimeoutError) do
      d = Armagh::Actions::ActionStateDocument.find_or_create(@config_coll, 'fred', 123, 10)
    end
  end

  def test_save_and_unlock
    expect_find_returns_nil
    @config_coll
      .expects(:find_one_and_update)
      .times(2)
      .returns(
        { 'name' => 'fred_state', 'type' => 'Armagh::Actions::ActionStateDocument', 'locked_by' => 123, 'locked_at' => Time.now, 'content' => {} },
        {}
      )
    d = Armagh::Actions::ActionStateDocument.find_or_create(@config_coll, 'fred', 123, 10)  
    assert_nothing_raised do
      d.save_and_unlock
    end
    assert_equal nil, d.locked_by
  end
  
  def test_save_and_unlock_without_lock
    expect_find_returns_nil
    @config_coll
      .expects(:find_one_and_update)
      .times(2)
      .returns( 
        { 'name' => 'fred_state', 'type' => 'Armagh::Actions::ActionStateDocument', 'locked_by' => nil, 'locked_at' => nil, 'content' => {} },
        {} 
      )
    d = Armagh::Actions::ActionStateDocument.find_or_create(@config_coll, 'fred', 123, 10)  
    e = assert_raise(Armagh::Actions::ActionStateError) do
      d.save_and_unlock
    end
    assert_equal nil, d.locked_by
  end
  
end
