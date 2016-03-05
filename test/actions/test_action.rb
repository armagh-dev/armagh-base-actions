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


require_relative '../coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../lib/armagh/actions'

class TestAction < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
  end

  def teardown
    Armagh::Action.defined_input_docspecs.clear
    Armagh::Action.defined_output_docspecs.clear
  end

  def test_define_input_docspec
    Armagh::Action.define_input_docspec('test_type1')
    Armagh::Action.define_input_docspec('test_type2', default_state: Armagh::DocState::READY, default_type: 'type')
    expected = {
        'test_type1' => {'default_state' => nil, 'default_type' => nil},
        'test_type2' => {'default_state' => 'ready', 'default_type' => 'type'},
    }
    assert_equal(expected, Armagh::Action.defined_input_docspecs)
  end

  def test_define_input_docspec_bad_name
    e = assert_raise(Armagh::ActionErrors::DocSpecError) {Armagh::Action.define_input_docspec(nil)}
    assert_equal 'Input DocSpec name must be a String.', e.message
    assert_empty Armagh::Action.defined_input_docspecs
  end

  def test_define_input_docspec_bad_default_state
    e = assert_raise(Armagh::ActionErrors::DocSpecError) {Armagh::Action.define_input_docspec('name', default_state: 'invalid')}
    assert_equal "Input DocSpec name's default_state is invalid.", e.message
    assert_empty Armagh::Action.defined_input_docspecs
  end

  def test_define_input_docspec_bad_default_type
    e = assert_raise(Armagh::ActionErrors::DocSpecError) {Armagh::Action.define_input_docspec('name', default_type: 123)}
    assert_equal "Input DocSpec name's default_type must be a String.", e.message
    assert_empty Armagh::Action.defined_input_docspecs
  end

  def test_define_output_docspec
    Armagh::Action.define_output_docspec('test_type1')
    Armagh::Action.define_output_docspec('test_type2', default_state: Armagh::DocState::READY, default_type: 'type')
    expected = {
        'test_type1' => {'default_state' => nil, 'default_type' => nil},
        'test_type2' => {'default_state' => 'ready', 'default_type' => 'type'},
    }
    assert_equal(expected, Armagh::Action.defined_output_docspecs)
  end

  def test_define_output_docspec_bad_name
    e = assert_raise(Armagh::ActionErrors::DocSpecError) {Armagh::Action.define_output_docspec(nil)}
    assert_equal 'Output DocSpec name must be a String.', e.message
    assert_empty Armagh::Action.defined_output_docspecs
  end

  def test_define_output_docspec_bad_default_state
    e = assert_raise(Armagh::ActionErrors::DocSpecError) {Armagh::Action.define_output_docspec('name', default_state: 'invalid')}
    assert_equal "Output DocSpec name's default_state is invalid.", e.message
    assert_empty Armagh::Action.defined_output_docspecs
  end

  def test_define_output_docspec_bad_default_type
    e = assert_raise(Armagh::ActionErrors::DocSpecError) {Armagh::Action.define_output_docspec('name', default_type: 123)}
    assert_equal "Output DocSpec name's default_type must be a String.", e.message
    assert_empty Armagh::Action.defined_output_docspecs
  end

  def test_valid
    action = Armagh::Action.new('name', @caller, @logger, {}, {}, {})
    action.class.stubs(:ancestors).returns([Armagh::SubscribeAction])
    assert_true action.valid?, action.validation_errors
    assert_empty action.validation_errors
  end

  def test_valid_bad_type
    action = Armagh::Action.new('name', @caller, @logger, {}, {}, {})
    assert_false action.valid?
    puts action.validation_errors['general']
    assert_equal(['Unknown Action Type Action.  Was Armagh::Parameterized but expected ["Armagh::ParseAction", "Armagh::SubscribeAction", "Armagh::PublishAction", "Armagh::CollectAction"].'],
                 action.validation_errors['general'])
  end

  def test_default_validate
    action = Armagh::Action.new('name', @caller, @logger, {}, {}, {})
    assert_nil action.validate
  end
end
