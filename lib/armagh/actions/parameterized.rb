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

require_relative 'parameter_definitions'
require_relative '../action_errors'

module Armagh
  class Parameterized
    extend ParameterDefinitions

    attr_reader :validation_errors

    def initialize(parameters)
      @parameters = parameters
      @validation_errors = {}
    end

    def valid?
      valid = true
      @validation_errors.clear

      valid &&= validate_required_params
      valid &&= validate_params
      valid &&= validate_general

      valid
    end

    def validate
      # Default has no grouped parameter validation
      nil
    end

    private def validate_required_params
      valid = true
      self.class.defined_parameters.select{|_k,v| v['required']}.keys.each do |param|
        unless @parameters.has_key?(param)
          valid = false
          @validation_errors['parameters'] ||= {}
          @validation_errors['parameters'][param] = 'Required parameter is missing.'
          next
        end
      end
      valid
    end

    private def validate_params
      valid = true
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
          if self.respond_to? callback
            begin
              response = self.send(callback, value)
            rescue => e
              valid = false
              @validation_errors['parameters'] ||= {}
              @validation_errors['parameters'][param] = "Validation callback failed with exception: #{e}"
              next
            end

            unless response.nil?
              valid = false
              @validation_errors['parameters'] ||= {}
              @validation_errors['parameters'][param] = response
              next
            end
          else
            valid = false
            @validation_errors['parameters'] ||= {}
            @validation_errors['parameters'][param] = "Invalid validation_callback.  Class does not respond to #{callback}."
            next
          end
        end
      end
      valid
    end

    def validate_general
      valid = true
      general_validation = validate
      unless general_validation.nil?
        valid = false
        @validation_errors['general'] = general_validation
      end
      valid
    end
  end
end
