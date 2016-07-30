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
require_relative '../../../lib/armagh/actions/parameterized'

require 'test/unit'
require 'mocha/test_unit'

module Armagh::Actions::ParameterDefinitions
  # Simply unloading and reloading the module breaks code coverage.
  # Can't call the class_variables method to overwite as they are protected from @class_vars (versus @member_vars or @@class_vars)
  def clear_defined_parameters
    @defined_parameters = nil
  end
end

class TestParameterized < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    @parameterized = Armagh::Actions::Parameterized.new({})
  end

  def teardown
    Armagh::Actions::Parameterized.clear_defined_parameters
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

    Armagh::Actions::Parameterized.define_parameter(name: name,
                                                    description: description,
                                                    type: type,
                                                    required: required,
                                                    default: default,
                                                    validation_callback: validation_callback,
                                                    prompt: prompt)

    assert_equal(expected, Armagh::Actions::Parameterized.defined_parameters)
  end

  def test_define_parameters_boolean
    name = 'name'
    description = 'description'
    type = Boolean
    required = false
    default = false
    validation_callback = 'callback'
    prompt = 'Number name blah'

    expected = {
        name => {'description' => description, 'type' => type, 'required' => required, 'default' => default, 'validation_callback' => validation_callback, 'prompt' => prompt}
    }

    Armagh::Actions::Parameterized.define_parameter(name: name,
                                                    description: description,
                                                    type: type,
                                                    required: required,
                                                    default: default,
                                                    validation_callback: validation_callback,
                                                    prompt: prompt)

    assert_equal(expected, Armagh::Actions::Parameterized.defined_parameters)
  end

  def test_define_parameters_encoded_string
    name = 'name'
    description = 'description'
    type = EncodedString
    required = false
    default = 'some string'
    validation_callback = 'callback'
    prompt = 'Number name blah'

    expected = {
        name => {'description' => description, 'type' => type, 'required' => required, 'default' => default, 'validation_callback' => validation_callback, 'prompt' => prompt}
    }

    Armagh::Actions::Parameterized.define_parameter(name: name,
                                                    description: description,
                                                    type: type,
                                                    required: required,
                                                    default: default,
                                                    validation_callback: validation_callback,
                                                    prompt: prompt)

    assert_equal(expected, Armagh::Actions::Parameterized.defined_parameters)
  end

  def test_define_parameters_errors
    e = assert_raise(Armagh::Actions::Errors::ParameterError) {
      Armagh::Actions::Parameterized.define_parameter(name: nil, description: '', type: '')
    }
    assert_equal('Parameter name must be a String.', e.message)

    e = assert_raise(Armagh::Actions::Errors::ParameterError) {
      Armagh::Actions::Parameterized.define_parameter(name: 'name', description: nil, type: '')
    }
    assert_equal("Parameter name's description must be a String.", e.message)

    e = assert_raise(Armagh::Actions::Errors::ParameterError) {
      Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: nil)
    }
    assert_equal("Parameter name's type must be a class.", e.message)

    e = assert_raise(Armagh::Actions::Errors::ParameterError) {
      Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: 'true')
    }
    assert_equal("Parameter name's required flag must be a Boolean.", e.message)

    e = assert_raise(Armagh::Actions::Errors::ParameterError) {
      Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: Boolean, required: false,
                                                      default: 123)
    }
    assert_equal("Parameter name's default must be a Boolean.  Was a Fixnum.", e.message)

    e = assert_raise(Armagh::Actions::Errors::ParameterError) {
      Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: EncodedString, required: false,
                                                      default: 123)
    }
    assert_equal("Parameter name's default must be a String (that will later be encoded).  Was a Fixnum.", e.message)

    e = assert_raise(Armagh::Actions::Errors::ParameterError) {
      Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: false,
                                             default: 123)
    }
    assert_equal("Parameter name's default must be a String.  Was a Fixnum.", e.message)

    e = assert_raise(Armagh::Actions::Errors::ParameterError) {
     Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: false,
                                            default: 'default', validation_callback: 123)
    }
    assert_equal("Parameter name's validation_callback must be a String.", e.message)

    e = assert_raise(Armagh::Actions::Errors::ParameterError) {
      Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: false,
                                             default: 'default', validation_callback: 'validation_callback',
                                             prompt: 123)
    }
    assert_equal("Parameter name's prompt must be a String.", e.message)

  end

  def test_define_parameters_duplicate
    Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: String)

    e = assert_raise(Armagh::Actions::Errors::ParameterError) {
      Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: String)
    }
    assert_equal("A parameter named 'name' already exists.", e.message)
  end

  def test_valid
    valid =  @parameterized.validate
    assert_true valid['valid']
    assert_empty valid['errors']
    assert_empty valid['warnings']
  end

  def test_valid_missing_required
    Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: true)

    valid =  @parameterized.validate
    assert_false valid['valid']
    assert_empty valid['warnings']
    assert_equal(["Required parameter 'name' is missing."], valid['errors'])
  end

  def test_valid_wrong_type
    Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: true)
    parameterized = Armagh::Actions::Parameterized.new({'name' => 123})
    valid =  parameterized.validate
    assert_false valid['valid']
    assert_empty valid['warnings']
    assert_equal(["Invalid type for 'name'.  Expected String but was Fixnum."], valid['errors'])
  end

  def test_valid_callback_not_defined
    Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: true, validation_callback: 'undefined')
    parameterized = Armagh::Actions::Parameterized.new({'name' => 'name'})

    valid =  parameterized.validate
    assert_false valid['valid']
    assert_empty valid['warnings']
    assert_equal(["Invalid validation_callback for 'name'.  Class does not respond to method 'undefined'."], valid['errors'])
  end

  def test_valid_callback_exception
    Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: true, validation_callback: 'raise_callback')
    parameterized = Armagh::Actions::Parameterized.new({'name' => 'name'})
    parameterized.stubs(:raise_callback).raises(RuntimeError.new('Exception!'))

    valid =  parameterized.validate
    assert_false valid['valid']
    assert_empty valid['warnings']
    assert_equal(["Validation callback of 'name' (method 'raise_callback') failed with exception: Exception!."], valid['errors'])
  end

  def test_valid_callback_failed
    Armagh::Actions::Parameterized.define_parameter(name: 'name', description: 'description', type: String, required: true, validation_callback: 'returns_callback')
    parameterized = Armagh::Actions::Parameterized.new({'name' => 'name'})
    parameterized.stubs(:returns_callback).returns('Callback was unsuccessful')
    valid =  parameterized.validate
    assert_false valid['valid']
    assert_empty valid['warnings']
    assert_equal(["Validation callback of 'name' (method 'returns_callback') failed with message: Callback was unsuccessful."], valid['errors'])
  end

  def test_valid_unexpected_param
    parameterized = Armagh::Actions::Parameterized.new({'name' => 'name'})
    valid =  parameterized.validate
    assert_true valid['valid']
    assert_empty valid['errors']
    assert_equal(["Parameter 'name' not defined for class Armagh::Actions::Parameterized."], valid['warnings'])
  end

  def test_custom_validation_failure
    @parameterized.stubs(:custom_validation).returns('General Failure')

    valid =  @parameterized.validate
    assert_false valid['valid']
    assert_empty valid['warnings']
    assert_equal(['Custom validation failed with message: General Failure'], valid['errors'])
  end

  def test_custom_validation_default
    assert_nil @parameterized.custom_validation
  end
end