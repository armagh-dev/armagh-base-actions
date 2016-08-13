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
require_relative '../../../lib/armagh/actions/encodable'

require 'test/unit'
require 'mocha/test_unit'

class Armagh::Actions::EncodableItem
  include Armagh::Actions::Encodable

  def initialize(caller, logger_name)
    @caller = caller
    @logger_name = logger_name
  end
end

class Caller
  attr_reader :method
  def log_info(log_name)
    @method = :info
    yield
  end

  def log_debug(log_name)
    @method = :debug
    yield
  end
end

class TestEncodable < Test::Unit::TestCase
  def setup
    @caller = mock('caller')
    @logger_name = 'logger_name'
    @encodable = Armagh::Actions::EncodableItem.new(@caller, @logger_name)
  end

  def test_fix_encoding_string
    object = 'test message'
    @caller.expects(:fix_encoding).with(@logger_name, object, nil)
    @encodable.fix_encoding(object)
  end

  def test_fix_encoding_array
    object = ['test message']
    @caller.expects(:fix_encoding).with(@logger_name, object, nil)
    @encodable.fix_encoding(object)
  end

  def test_fix_encoding_hash
    object = {'test' => true}
    @caller.expects(:fix_encoding).with(@logger_name, object, nil)
    @encodable.fix_encoding(object)
  end

  def test_fix_encoding_bad_type
    object = 123
    assert_raise(ArgumentError){@encodable.fix_encoding(object)}
  end

  def fix_encoding_proposed
    object = 'test message'
    proposed = 'utf-8'
    @caller.expects(:fix_encoding).with(@logger_name, object, proposed)
    @encodable.fix_encoding(object, proposed)
  end
end
