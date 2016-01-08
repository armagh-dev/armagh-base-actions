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

class Boolean
  def self.bool?(val)
    val == true || val == false
  end
end

module Armagh
  class ParameterError < StandardError; end
  class ActionExecuteNotImplemented < StandardError; end

  class Action
    DEFINED_PARAMETERS = {}

    attr_reader :validation_errors

    def initialize(caller, logger, config)
      @caller = caller
      @logger = logger
      @config = config
      @validation_errors = {}
    end

    def config=(config)
      @config = config
    end

    def self.define_parameter(name, description, type, options={})
      raise ParameterError.new 'Parameter name undefined' unless name
      raise ParameterError.new 'Parameter name needs to be a String' unless name.is_a? String

      raise ParameterError.new "Parameter #{name}'s description is undefined" unless description
      raise ParameterError.new "Parameter #{name}'s description must be a String" unless description.is_a? String

      raise ParameterError.new "Parameter #{name}'s type is undefined" unless type
      raise ParameterError.new "Parameter #{name}'s type must be a class" unless type.is_a? Class

      allowed_options = %w(required default validation_callback prompt)
      unknown_options = options.keys - allowed_options
      raise ParameterError.new "The following options for #{name} are unknown: #{unknown_options}.  Allowed are #{allowed_options}" unless unknown_options.empty?

      raise ParameterError.new "Parameter #{name}'s prompt must be a String" if options['prompt'] && !options['prompt'].is_a?(String)
      raise ParameterError.new "Parameter #{name}'s default is the wrong type" if options.has_key?('default') && !(options['default'].is_a?(type) ||  Boolean.bool?(options['default']))
      raise ParameterError.new "Parameter #{name}'s required flag is not a boolean" if options['required'] && !Boolean.bool?(options['required'])

      param_config = {'description' => description, 'type' => type, 'required' => options['required'] || false, 'default' => options['default'], 'validation_callback' => options['validation_callback'], 'prompt' => options['prompt']}

      if DEFINED_PARAMETERS.has_key? name
        raise ParameterError.new "A parameter named '#{name}' already exists."
      else
        DEFINED_PARAMETERS[name] = param_config
      end
    end

    def execute(doc_content, doc_meta)
      raise ActionExecuteNotImplemented.new "The execute method needs to be overwritten by #{self.class}"
    end

    def valid?
      valid = true
      @validation_errors ||= {}
      @validation_errors.clear

      DEFINED_PARAMETERS.select{|_k,v| v['required']}.keys.each do |param|
        unless @config.has_key?(param)
          valid = false
          @validation_errors[param] = 'Required parameter is missing.'
          next
        end
      end

      @config.each do |param, value|
        expected_type = DEFINED_PARAMETERS[param]['type']
        unless value.is_a?(expected_type) || (expected_type == Boolean &&(value.is_a?(TrueClass) || value.is_a?(FalseClass)))
          valid = false
          @validation_errors[param] = "Invalid type.  Expected #{expected_type} but was #{value.class}."
          next
        end

        callback = DEFINED_PARAMETERS[param]['validation_callback']
        if callback
          response = self.send(callback, value)
          unless response.nil?
            valid = false
            @validation_errors[param] = response
            next
          end
        end
      end

      action_validation = validate if valid
      unless action_validation.nil?
        valid = false
        @validation_errors['_all'] = action_validation
      end

      valid
    end

    def validate
      # Default has no Action level validation
      nil
    end

    def insert_document(id = nil, content, meta)
      @caller.insert_document(id, content, meta)
    end

    def update_document(id, content, meta)
      @caller.update_document(id, content, meta)
    end

    def insert_or_update_document(id, content, meta)
      @caller.insert_or_update_document(id, content, meta)
    end

    def self.defined_parameters
      DEFINED_PARAMETERS
    end
  end
end
