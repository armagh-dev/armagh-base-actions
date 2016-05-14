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

require 'tmpdir'

require_relative '../action_errors'

class Boolean
  def self.bool?(val)
    val == true || val == false
  end
end

module Armagh
  module ParameterDefinitions
    def define_parameter(name:, description:, type:, required: false, default: nil, validation_callback: nil, prompt: nil)
      raise ActionErrors::ParameterError, 'Parameter name must be a String.' unless name.is_a? String
      raise ActionErrors::ParameterError, "Parameter #{name}'s description must be a String." unless description.is_a? String
      raise ActionErrors::ParameterError, "Parameter #{name}'s type must be a class." unless type.is_a? Class
      raise ActionErrors::ParameterError, "Parameter #{name}'s required flag must be a Boolean." unless Boolean.bool?(required)
      raise ActionErrors::ParameterError, "Parameter #{name}'s default must be a #{type}." if default && !(default.is_a?(type) ||  (type == Boolean && Boolean.bool?(default)))
      raise ActionErrors::ParameterError, "Parameter #{name}'s validation_callback must be a String." if validation_callback && !validation_callback.is_a?(String)
      raise ActionErrors::ParameterError, "Parameter #{name}'s prompt must be a String." if prompt && !prompt.is_a?(String)
      raise ActionErrors::ParameterError, "Parameter #{name} cannot have a default value and be required." if required && default

      param_config = {'description' => description, 'type' => type, 'required' => required, 'default' => default, 'validation_callback' => validation_callback, 'prompt' => prompt}

      @defined_parameters ||= {}

      if @defined_parameters.has_key? name
        raise ActionErrors::ParameterError, "A parameter named '#{name}' already exists."
      else
        @defined_parameters[name] = param_config
      end
    end

    def defined_parameters
      parameters = {}
      parameters.merge! @defined_parameters if @defined_parameters

      others = ancestors.reject{|a| a==self}

      others.each do |ancestor|
        if ancestor.respond_to?(:defined_parameters)
          parameters.merge! ancestor.defined_parameters
        end
      end
      parameters
    end
  end
end