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
require_relative '../../../lib/armagh/actions/loggable'

require 'test/unit'
require 'mocha/test_unit'

class Armagh::Actions::LoggableItem
  include Armagh::Actions::Loggable

  def initialize(name, caller, logger_name)
    @name = name
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

class TestLoggable < Test::Unit::TestCase
  def setup
    @caller = mock('caller')
    @logger_name = 'logger_name'
    @name = 'test_object'
    @loggable = Armagh::Actions::LoggableItem.new(@name, @caller, @logger_name)
  end

  def test_log_debug
    message = 'test message'
    @caller.expects(:log_debug).with(@logger_name, message)
    @loggable.log_debug(message)
  end

  def test_log_debug_block
    caller = Caller.new
    loggable = Armagh::Actions::LoggableItem.new(@name, caller, @logger_name)
    block_called = false
    loggable.log_debug {block_called = true}
    assert_true block_called
    assert_equal :debug, caller.method
  end

  def test_log_info
    message = 'test message'
    @caller.expects(:log_info).with(@logger_name, message)
    @loggable.log_info(message)
  end

  def test_log_info_block
    caller = Caller.new
    loggable = Armagh::Actions::LoggableItem.new(@name, caller, @logger_name)
    block_called = false
    loggable.log_info {block_called = true}
    assert_true block_called
    assert_equal :info, caller.method
  end

  def test_notify_dev
    message = 'error message'
    @caller.expects(:notify_dev).with(@logger_name, @name, message)
    @loggable.notify_dev message
  end

  def test_notify_ops
    message = 'error message'
    @caller.expects(:notify_ops).with(@logger_name, @name, message)
    @loggable.notify_ops message
  end

  def test_logger
    @caller.expects(:get_logger).with(@logger_name)
    @loggable.logger
  end
end
