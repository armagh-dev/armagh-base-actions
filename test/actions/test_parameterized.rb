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

class TestParameterized < Test::Unit::TestCase

  def setup
    load File.join(__dir__, '..', '..', 'lib', 'armagh', 'actions', 'parameterized.rb')

    @logger = mock
    @caller = mock
    @parameterized = Armagh::Parameterized.new({})
  end

  def teardown
    Armagh.send(:remove_const, :Parameterized)
  end

  def test_boolean
    assert_true Boolean.bool?(true)
    assert_true Boolean.bool?(false)

    assert_false Boolean.bool?('true')
    assert_false Boolean.bool?('false')

    assert_false Boolean.bool?(0)
    assert_false Boolean.bool?(1)
  end

  def test_define_parameters
    name = 'name'
    description = 'description'
    type = Numeric
    required = false
    default = 0
    validation_callback = 'callback'
    prompt = 'Number name blah'

    expected = {
        name => {'description' => description, 'type' => type, 'required' => required, 'default' => default, 'validation_callback' => validation_callback, 'prompt' => prompt}
    }

    Armagh::Parameterized.define_parameter(name: name, description: description, type: type, required: required,
                                           default: default, validation_callback: validation_callback,
                                           prompt: prompt)

    assert_equal(expected, Armagh::Parameterized.defined_parameters)
  end

  def test_define_parameters_errors
    e = assert_raise(Armagh::ActionErrors::ParameterError) {
      Armagh::Parameterized.define_parameter(name: nil, description: '', type: '')
    }
    assert_equal('Parameter name must be a String.', e.message)

    e = assert_raise(Armagh::ActionErrors::ParameterError) {
      Armagh::Parameterized.define_parameter(name: 'name', description: nil, type: '')
    }
    assert_equal("Parameter name's description must be a String.", e.message)

    e = assert_raise(Armagh::ActionErrors::ParameterError) {
      Armagh::Parameterized.define_parameter(name: 'name', description: 'description', type: nil)
    }
    assert_equal("Parameter name's type must be a class.", e.message)

    e = assert_raise(Armagh::ActionErrors::ParameterError) {
      Armagh::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: 'true')
    }
    assert_equal("Parameter name's required flag must be a Boolean.", e.message)

    e = assert_raise(Armagh::ActionErrors::ParameterError) {
      Armagh::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: false,
                                             default: 123)
    }
    assert_equal("Parameter name's default must be a String.", e.message)

    e = assert_raise(Armagh::ActionErrors::ParameterError) {
     Armagh::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: false,
                                            default: 'default', validation_callback: 123)
    }
    assert_equal("Parameter name's validation_callback must be a String.", e.message)

    e = assert_raise(Armagh::ActionErrors::ParameterError) {
      Armagh::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: false,
                                             default: 'default', validation_callback: 'validation_callback',
                                             prompt: 123)
    }
    assert_equal("Parameter name's prompt must be a String.", e.message)

    e = assert_raise(Armagh::ActionErrors::ParameterError) {
      Armagh::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: true,
                                             default: 'default', validation_callback: 'validation_callback',
                                             prompt: 'prompt')
    }
    assert_equal('Parameter name cannot have a default value and be required.', e.message)
  end

  def test_define_parameters_duplicate
    Armagh::Parameterized.define_parameter(name: 'name', description: 'description', type: String)

    e = assert_raise(Armagh::ActionErrors::ParameterError) {
      Armagh::Parameterized.define_parameter(name: 'name', description: 'description', type: String)
    }
    assert_equal("A parameter named 'name' already exists.", e.message)
  end

  def test_valid
    assert_true @parameterized.valid?
  end

  def test_valid_missing_required
    Armagh::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: true)
    assert_false @parameterized.valid?
    assert_equal('Required parameter is missing.', @parameterized.validation_errors['parameters']['name'])
  end

  def test_valid_wrong_type
    Armagh::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: true)
    parameterized = Armagh::Parameterized.new({'name' => 123})
    assert_false parameterized.valid?
    assert_equal('Invalid type.  Expected String but was Fixnum.', parameterized.validation_errors['parameters']['name'])
  end

  def test_valid_callback_not_defined
    Armagh::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: true, validation_callback: 'undefined')
    parameterized = Armagh::Parameterized.new({'name' => 'name'})
    assert_false parameterized.valid?
    assert_equal('Invalid validation_callback.  Class does not respond to undefined.', parameterized.validation_errors['parameters']['name'])
  end

  def test_valid_callback_exception
    Armagh::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: true, validation_callback: 'raise_callback')
    parameterized = Armagh::Parameterized.new({'name' => 'name'})
    parameterized.stubs(:raise_callback).raises(RuntimeError.new('Exception!'))
    assert_false parameterized.valid?
    assert_equal('Validation callback failed with exception: Exception!', parameterized.validation_errors['parameters']['name'])
  end

  def test_valid_callback_failed
    Armagh::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: true, validation_callback: 'returns_callback')
    parameterized = Armagh::Parameterized.new({'name' => 'name'})
    parameterized.stubs(:returns_callback).returns('Callback was unsuccessful')
    assert_false parameterized.valid?
    assert_equal('Callback was unsuccessful', parameterized.validation_errors['parameters']['name'])
  end

  def test_valid_general_validation_failure
    @parameterized.stubs(:validate).returns('General Failure')
    assert_false @parameterized.valid?
    assert_equal('General Failure', @parameterized.validation_errors['general'])
  end

  def test_validation_default
    assert_nil @parameterized.validate
  end
end
