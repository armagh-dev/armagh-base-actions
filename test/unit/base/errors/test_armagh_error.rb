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

require_relative '../../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../../lib/armagh/base/errors/armagh_error'



class TestArmaghError < Test::Unit::TestCase

  def setup
    Object.const_set("DevNotifier", stub) unless Object.const_defined?("DevNotifier")
    Object.const_set("OpsNotifier", stub) unless Object.const_defined?("OpsNotifier")
  end

  test ".notifiers returns an Array if @notifiers is nil" do
    ArmaghError.instance_variable_set("@notifiers", nil)
    assert_equal [], ArmaghError.notifiers
  end

  test "can set notifiers on the class" do
    test_notifier = mock('notifier')
    ArmaghError.instance_variable_set("@notifiers", [test_notifier])

    assert_equal [test_notifier], ArmaghError.notifiers
  end

  test ".notifies sets notifiers on the class" do
    ArmaghError.stubs(:defined_notifiers).returns([DevNotifier])
    ArmaghError.notifies(:dev)

    assert ArmaghError.notifiers.include?(::DevNotifier)
  end

  test ".notifies with arg of :none removes all notifiers" do
    ArmaghError.stubs(:defined_notifiers).returns([DevNotifier])
    ArmaghError.notifies(:dev)
    ArmaghError.notifies(:none)

    assert_false ArmaghError.notifiers.include?(::DevNotifier)
    assert_empty ArmaghError.notifiers
  end

  test ".notifies raises exception if notifier can't be found" do
    ArmaghError.stubs(:defined_notifiers).returns([DevNotifier])
    assert_raises(ArmaghError::NotifierNotFoundError) {
      ArmaghError.notifies(:foo)
    }
  end

  test ".notifies raises exception if args aren't symbols" do
    ArmaghError.stubs(:defined_notifiers).returns([DevNotifier])

    assert_raises(ArmaghError::InvalidArgument) {
      ArmaghError.notifies("dev")
    }
  end

  test "instance includes notifiers set on the class" do
    test_notifier = mock('notifier')
    ArmaghError.notifiers << test_notifier

    error = ArmaghError.new
    assert error.notifiers.include?(test_notifier)
  end

  test "instance includes notifiers set on the superclass" do
    test_notifier = mock('notifier')
    ArmaghError.notifiers << test_notifier
    class CustomErrorWithoutNotifiers < ArmaghError; end

    error = CustomErrorWithoutNotifiers.new
    assert error.notifiers.include?(test_notifier)
  end

  test "#notify calls notify method on each notifier" do
    DevNotifier.expects(:new).returns(stub('notifier_instance', :notify => true))
    ArmaghError.stubs(:defined_notifiers).returns([DevNotifier])
    ArmaghError.notifies(:dev)

    ArmaghError.new.notify
  end

  test "can selectively call #notify_dev if error is set to notify dev" do
    mock_caller = mock('caller')
    calling_action = mock('calling_action', name: 'some action', logger_name: 'some logger', caller: mock_caller)
    mock_caller.expects(:notify_dev)

    ArmaghError.stubs(:defined_notifiers).returns([DevNotifier, OpsNotifier])
    ArmaghError.notifies(:dev, :ops)

    ArmaghError.new.notify_dev(calling_action)
  end

  test "can selectively call #notify_ops if error is set to notify ops" do
    mock_caller = mock('caller')
    calling_action = mock('calling_action', name: 'some action', logger_name: 'some logger', caller: mock_caller)
    mock_caller.expects(:notify_ops)
    ArmaghError.stubs(:defined_notifiers).returns([DevNotifier, OpsNotifier])
    ArmaghError.notifies(:dev, :ops)

    ArmaghError.new.notify_ops(calling_action)
  end

  test "bubbles up methods that don't match a defined notifier" do
    calling_action = mock('calling_action')
    ArmaghError.stubs(:defined_notifiers).returns([DevNotifier, OpsNotifier])
    ArmaghError.notifies(:dev, :ops)

    assert_raises(NoMethodError) {
      ArmaghError.new.notify_foobar(calling_action)
    }
  end

end
