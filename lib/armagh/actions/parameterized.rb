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

require_relative '../errors'

class Boolean
  def self.bool?(val)
    val == true || val == false
  end
end

module Armagh
  # TODO Add a deduplication by action instance (string)
  # TODO Add a deduplication configuration for time to live per action instance

  class Parameterized
    attr_reader :validation_errors

    def initialize
      @validation_errors = {}
    end

    def parameters=(parameters)
      @parameters = parameters
    end

    def self.define_parameter(name:, description:, type:, required: false, default: nil, validation_callback: nil, prompt: nil)
      raise ActionErrors::ParameterError.new 'Parameter name undefined' unless name
      raise ActionErrors::ParameterError.new 'Parameter name needs to be a String' unless name.is_a? String

      raise ActionErrors::ParameterError.new "Parameter #{name}'s description is undefined" unless description
      raise ActionErrors::ParameterError.new "Parameter #{name}'s description must be a String" unless description.is_a? String

      raise ActionErrors::ParameterError.new "Parameter #{name}'s type is undefined" unless type
      raise ActionErrors::ParameterError.new "Parameter #{name}'s type must be a class" unless type.is_a? Class

      raise ActionErrors::ParameterError.new "Parameter #{name}'s prompt must be a String" if prompt && !prompt.is_a?(String)
      raise ActionErrors::ParameterError.new "Parameter #{name}'s default is the wrong type" if default && !(default.is_a?(type) ||  Boolean.bool?(default))
      raise ActionErrors::ParameterError.new "Parameter #{name}'s required flag is not a boolean" unless Boolean.bool?(required)

      param_config = {'description' => description, 'type' => type, 'required' => required, 'default' => default, 'validation_callback' => validation_callback, 'prompt' => prompt}

      if defined_parameters.has_key? name
        raise ActionErrors::ParameterError.new "A parameter named '#{name}' already exists."
      else
        defined_parameters[name] = param_config
      end
    end

    def self.defined_parameters
      @defined_parameters ||= {}
    end

    # TODO This can be cleaned up.
    def valid?
      valid = true
      @validation_errors.clear

      self.class.defined_parameters.select{|_k,v| v['required']}.keys.each do |param|
        unless @parameters.has_key?(param)
          valid = false
          @validation_errors['parameters'] ||= {}
          @validation_errors['parameters'][param] = 'Required parameter is missing.'
          next
        end
      end

      return false unless valid

      @parameters.each do |param, value|
        expected_type = self.class.defined_parameters[param]['type']
        unless value.is_a?(expected_type) || (expected_type == Boolean &&(Boolean.bool?(value)))
          valid = false
          @validation_errors['parameters'] ||= {}
          @validation_errors['parameters'][param] = "Invalid type.  Expected #{expected_type} but was #{value.class}."
          next
        end

        return false unless valid

        callback = self.class.defined_parameters[param]['validation_callback']
        if callback
          response = self.send(callback, value) # TODO Trap if validation_callback raised an exception (like the method had a typo in the name)
          unless response.nil?
            valid = false
            @validation_errors['parameters'] ||= {}
            @validation_errors['parameters'][param] = response
            next
          end
        end
      end

      return false unless valid

      general_validation = validate if valid
      unless general_validation.nil?
        valid = false
        @validation_errors['general'] = general_validation
      end

      valid
    end

    def validate
      # Default has no grouped parameter validation
      nil
    end
  end
end
