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
require_relative 'errors'

module Armagh
  module Actions

    class Parameterized
      extend ParameterDefinitions
      attr_accessor :parameters

      def initialize(parameters)
        @parameters = parameters
        @validation_errors = []
        @validation_warnings = []
      end

      def validate
        @validation_errors.clear
        @validation_warnings.clear

        validate_required_params && validate_params && validate_general

        {'valid' => @validation_errors.empty?, 'errors' => @validation_errors, 'warnings' => @validation_warnings}
      end

      def custom_validation
        # Default has no grouped parameter validation
        nil
      end

      private def validate_required_params
        valid = true
        self.class.defined_parameters.select { |_k, v| v['required'] }.keys.each do |param|
          unless @parameters.has_key?(param)
            valid = false
            @validation_errors << "Required parameter '#{param}' is missing."
          end
        end
        valid
      end

      private def validate_params
        valid = true
        @parameters.each do |param, value|
          if self.class.defined_parameters[param]
            expected_type = self.class.defined_parameters[param]['type']

            begin
              expected_type.new(value) unless value.is_a? expected_type
            rescue
              @validation_errors << "Invalid type for '#{param}'.  Expected #{expected_type} but was #{value.class}."
            end

            return false unless valid

            callback = self.class.defined_parameters[param]['validation_callback']
            if callback
              if self.respond_to? callback
                begin
                  response = self.send(callback, value)
                rescue => e
                  valid = false
                  @validation_errors << "Validation callback of '#{param}' (method '#{callback}') failed with exception: #{e}."
                  next
                end

                unless response.nil?
                  valid = false
                  @validation_errors << "Validation callback of '#{param}' (method '#{callback}') failed with message: #{response}."
                  next
                end
              else
                valid = false
                @validation_errors << "Invalid validation_callback for '#{param}'.  Class does not respond to method '#{callback}'."
                next
              end
            end
          else
            @validation_warnings << "Parameter '#{param}' not defined for class #{self.class}."
          end
        end
        valid
      end


      def validate_general
        valid = true
        general_validation = custom_validation
        unless general_validation.nil?
          valid = false
          @validation_errors << "Custom validation failed with message: #{general_validation}"
        end
        valid
      end
            
    end
  end
end
