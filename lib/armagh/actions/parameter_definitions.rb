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

require_relative 'errors.rb'
require_relative '../common/boolean.rb'
require_relative '../common/encoded_string.rb'

module Armagh
  module Actions
    module ParameterDefinitions
      
      def define_parameter(name:, description:, type:, required: false, default: nil, validation_callback: nil, prompt: nil)
        raise Errors::ParameterError, 'Parameter name must be a String.' unless name.is_a? String
        raise Errors::ParameterError, "Parameter #{name}'s description must be a String." unless description.is_a? String
        raise Errors::ParameterError, "Parameter #{name}'s type must be a class." unless type.is_a? Class
        raise Errors::ParameterError, "Parameter #{name}'s required flag must be a Boolean." unless Boolean.bool?(required)
        raise Errors::ParameterError, "Parameter #{name}'s validation_callback must be a String." if validation_callback && !validation_callback.is_a?(String)
        raise Errors::ParameterError, "Parameter #{name}'s prompt must be a String." if prompt && !prompt.is_a?(String)

        if default
          if type == Boolean
            raise Errors::ParameterError, "Parameter #{name}'s default must be a #{type}.  Was a #{default.class}." unless Boolean.bool? default
          elsif type == EncodedString
            raise Errors::ParameterError, "Parameter #{name}'s default must be a String (that will later be encoded).  Was a #{default.class}." unless default.is_a? String
          else
            raise Errors::ParameterError, "Parameter #{name}'s default must be a #{type}.  Was a #{default.class}." unless default.is_a? type
          end
        end

        param_config = {'description' => description, 'type' => type, 'required' => required, 'default' => default, 'validation_callback' => validation_callback, 'prompt' => prompt }

        @defined_parameters ||= {}

        if @defined_parameters.has_key? name
          raise Errors::ParameterError, "A parameter named '#{name}' already exists."
        else
          @defined_parameters[name] = param_config
        end
      end

      def defined_parameters
        parameters = {}
        parameters.merge! @defined_parameters if @defined_parameters

        others = ancestors.reject { |a| a==self }

        others.each do |ancestor|
          if ancestor.respond_to?(:defined_parameters)
            parameters.merge! ancestor.defined_parameters
          end
        end
        parameters
      end
    
      def defined_parameter_defaults
        Hash[defined_parameters.collect{ |k,v| [ k, v['default']] unless v['default'].nil?}.compact]
      end
      
      def defined_parameter_group( group_name )
        defined_parameters.select{ |k,v| v['group'] == group_name }
      end
    end
  end
end
