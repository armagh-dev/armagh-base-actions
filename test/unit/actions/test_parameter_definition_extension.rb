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
require_relative '../../../lib/armagh/actions'
require_relative '../../../lib/armagh/actions/parameter_definitions'

require 'test/unit'
require 'mocha/test_unit'

module Helper
  extend Armagh::Actions::ParameterDefinitions

  define_parameter name: 'test_parameter', description: 'Test Parameter', type: String
end

class ExampleAction < Armagh::Actions::Action
  include Helper
end

class TestParameterDefinitionExtension < Test::Unit::TestCase

  def test_defined_parameters_from_helper
    expected = {'test_parameter' =>{'description' => 'Test Parameter', 'type' =>String, 'required' =>false, 'default' =>nil, 'validation_callback' =>nil, 'prompt' =>nil}}
    assert_equal(expected, ExampleAction.defined_parameters)
  end
  # Deferred all testing of ParameterDefinitions to test_parameterized since ParameterDefinitions is a mixin
end