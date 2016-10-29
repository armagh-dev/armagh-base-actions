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

module Armagh
  module Support
    module Oracle
      class OCI8
        def initialize(_); end
      end
    end
  end
end

require_relative '../../../lib/armagh/support/oracle'

class TestOracle < Test::Unit::TestCase
  include Armagh::Support::Oracle

  def setup
    cursor = mock('cursor')
    cursor.stubs(:define)
    cursor.stubs(:exec)
    cursor.stubs(:fetch_hash).yields({key: 'value'})
    cursor.stubs(:close)
    Armagh::Support::Oracle::OCI8.any_instance.stubs(:parse).returns(cursor)
    Armagh::Support::Oracle::OCI8.any_instance.stubs(:logoff)

    @config = mock('config')
    oracle  = mock('oracle')
    oracle.stubs(:db_connection_string)
    oracle.stubs(:type_bindings)
    @config.stubs(:oracle).returns(oracle)
  end

  def test_query_oracle
    query_oracle('<sql statement>', @config) do |row|
      expected = {key: 'value'}
      assert_equal expected, row
    end
  end

  def test_query__oracle_invalid
    e = assert_raise InvalidQueryError do
      query_oracle(nil, nil)
    end
    assert_equal 'Query must be a String, instead: NilClass', e.message
  end

  def test_query_oracle_empty
    e = assert_raise InvalidQueryError do
      query_oracle('', nil)
    end
    assert_equal 'Query cannot be empty', e.message
  end

  def test_private_constant_oracle_client
    e = assert_raise NameError do
      Armagh::Support::Oracle::OracleClient.new
    end
    assert_equal 'private constant Armagh::Support::Oracle::OracleClient referenced', e.message
  end

end
