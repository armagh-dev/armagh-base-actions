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
    Armagh::Actions::Action.class_eval('@defined_input_type = nil')
    Armagh::Actions::Action.defined_output_docspecs.clear
  end

  def test_define_input_type
    type = 'test_type1'
    Armagh::Actions::Action.define_input_type type
    assert_equal(type, Armagh::Actions::Action.defined_input_type)
  end

  def test_define_input_type_bad_name
    type = 123
    e = assert_raise(Armagh::Documents::Errors::DocSpecError) {Armagh::Actions::Action.define_input_type(type)}
    assert_equal "Default type #{type} must be a String.", e.message
    assert_nil Armagh::Actions::Action.defined_input_type
  end

  def test_define_output_docspec
    Armagh::Actions::Action.define_output_docspec('test_type1')
    Armagh::Actions::Action.define_output_docspec('test_type2', default_state: Armagh::Documents::DocState::READY, default_type: 'type')
    expected = {
        'test_type1' => {'default_state' => nil, 'default_type' => nil},
        'test_type2' => {'default_state' => 'ready', 'default_type' => 'type'},
    }
    assert_equal(expected, Armagh::Actions::Action.defined_output_docspecs)
  end

  def test_define_output_docspec_bad_name
    e = assert_raise(Armagh::Documents::Errors::DocSpecError) {Armagh::Actions::Action.define_output_docspec(nil)}
    assert_equal 'Output DocSpec name must be a String.', e.message
    assert_empty Armagh::Actions::Action.defined_output_docspecs
  end

  def test_define_output_docspec_bad_default_state
    e = assert_raise(Armagh::Documents::Errors::DocSpecError) {Armagh::Actions::Action.define_output_docspec('name', default_state: 'invalid')}
    assert_equal "Output DocSpec name's default_state is invalid.", e.message
    assert_empty Armagh::Actions::Action.defined_output_docspecs
  end

  def test_define_output_docspec_bad_default_type
    e = assert_raise(Armagh::Documents::Errors::DocSpecError) {Armagh::Actions::Action.define_output_docspec('name', default_type: 123)}
    assert_equal "Output DocSpec name's default_type must be a String.", e.message
    assert_empty Armagh::Actions::Action.defined_output_docspecs
  end

  def test_valid
    action = Armagh::Actions::Action.new('name', @caller, 'logger_name', {}, {})
    action.class.stubs(:ancestors).returns([Armagh::Actions::Consume])
    valid = action.validate
    assert_true valid['valid']
    assert_empty valid['errors']
    assert_empty valid['warnings']
  end

  def test_valid_bad_type
    action = Armagh::Actions::Action.new('name', @caller, 'logger_name', {}, {})
    valid = action.validate
    assert_false valid['valid']
    assert_equal(['Unknown Action Type Actions::Action.  Expected to be a descendant of ["Armagh::Actions::Split", "Armagh::Actions::Consume", "Armagh::Actions::Publish", "Armagh::Actions::Collect"].'],
                 valid['errors'])
    assert_empty valid['warnings']
  end
end
