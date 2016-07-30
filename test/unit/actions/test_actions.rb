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

require_relative '../../../lib/armagh/actions'

class Action1 < Armagh::Actions::Action; end
class Action2 < Armagh::Actions::Action; end

class Divider1 < Armagh::Actions::Divide; end
class Divider2 < Armagh::Actions::Divide; end

module Armagh::StandardActions
  def self.clean
    constants.each { |c| send(:remove_const, c) }
  end

  def self.add_class(clazz)
    const_set(clazz.name, clazz)
  end
end

module Armagh::CustomActions
  def self.clean
    constants.each { |c| send(:remove_const, c) }
  end

  def self.add_class(clazz)
    const_set(clazz.name, clazz)
  end
end

module Armagh::Actions
  def self.clean
    @defined_actions = nil
    @defined_dividers = nil
  end
end

class TestActions < Test::Unit::TestCase
  def setup
    Armagh::CustomActions.clean
    Armagh::StandardActions.clean
    Armagh::Actions.clean
  end

  def test_defined_actions_none
    assert_empty Armagh::Actions.defined_actions
  end

  def test_available_custom_actions
    Armagh::CustomActions.add_class(Action1)
    assert_equal(1, Armagh::Actions.defined_actions.length)
    assert_equal(Action1, Armagh::Actions.defined_actions.first)
  end

  def test_available_standard_actions
    Armagh::StandardActions.add_class Action1
    assert_equal(1, Armagh::Actions.defined_actions.length)
    assert_equal(Action1, Armagh::Actions.defined_actions.first)
  end

  def test_available_custom_and_standard_actions
    Armagh::CustomActions.add_class(Action1)
    Armagh::StandardActions.add_class(Action2)

    available = Armagh::Actions.defined_actions
    assert_equal(2, available.length)
    assert_includes(available, Action1)
    assert_includes(available, Action2)
    Armagh::StandardActions.constants.inspect
  end

  def test_defined_dividers_none
    assert_empty Armagh::Actions.defined_dividers
  end

  def test_available_custom_dividers
    Armagh::CustomActions.add_class(Divider1)
    assert_equal(1, Armagh::Actions.defined_dividers.length)
    assert_equal(Divider1, Armagh::Actions.defined_dividers.first)
  end

  def test_available_standard_dividers
    Armagh::StandardActions.add_class Divider1
    assert_equal(1, Armagh::Actions.defined_dividers.length)
    assert_equal(Divider1, Armagh::Actions.defined_dividers.first)
  end

  def test_available_custom_and_standard_dividers
    Armagh::CustomActions.add_class(Divider1)
    Armagh::StandardActions.add_class(Divider2)
    available = Armagh::Actions.defined_dividers
    assert_equal(2, available.length)
    assert_includes(available, Divider1)
    assert_includes(available, Divider2)
    Armagh::StandardActions.constants.inspect
  end
end