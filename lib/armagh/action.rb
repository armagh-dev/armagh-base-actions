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

require_relative 'doc_state'

class Boolean
  def self.bool?(val)
    val == true || val == false
  end
end

module Armagh
  class ParameterError < StandardError; end
  class ActionExecuteNotImplemented < StandardError; end
  class DoctypeError < StandardError; end

  class Action
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

      if defined_parameters.has_key? name
        raise ParameterError.new "A parameter named '#{name}' already exists."
      else
        defined_parameters[name] = param_config
      end
    end

    def self.defined_parameters
      @defined_parameters ||= {}
    end

    def self.define_default_input_doctype(input_doctype)
      raise DoctypeError.new 'Default Input Doctype already defined' if @default_input_doctype
      @default_input_doctype = input_doctype.freeze
    end

    def self.define_default_output_doctype(output_doctype)
      raise DoctypeError.new 'Default Output Doctype already defined' if @default_output_doctype
      @default_output_doctype = output_doctype.freeze
    end

    def self.default_input_doctype
      @default_input_doctype
    end

    def self.default_output_doctype
      @default_output_doctype
    end

    def execute(action_doc)
      raise ActionExecuteNotImplemented.new "The execute method needs to be overwritten by #{self.class}"
    end

    def valid?
      valid = true
      @validation_errors ||= {}
      @validation_errors.clear

      self.class.defined_parameters.select{|_k,v| v['required']}.keys.each do |param|
        unless @config.has_key?(param)
          valid = false
          @validation_errors[param] = 'Required parameter is missing.'
          next
        end
      end

      @config.each do |param, value|
        expected_type = self.class.defined_parameters[param]['type']
        unless value.is_a?(expected_type) || (expected_type == Boolean &&(value.is_a?(TrueClass) || value.is_a?(FalseClass)))
          valid = false
          @validation_errors[param] = "Invalid type.  Expected #{expected_type} but was #{value.class}."
          next
        end

        callback = self.class.defined_parameters[param]['validation_callback']
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

    # Insert a document
    def insert_document(id: nil, content:, meta:, state: DocState::PUBLISHED)
      @caller.insert_document(id, content, meta, state)
    end

    # Update a prexisting document
    def update_document(id:, content:, meta:, state: DocState::PUBLISHED)
      @caller.update_document(id, content, meta, state)
    end

    # Update a preexisting document if it exists.  If not, create a new one.
    def insert_or_update_document(id:, content:, meta:, state: DocState::PUBLISHED)
      @caller.insert_or_update_document(id, content, meta, state)
    end

    # Lock and enable modification of a document.  If the document exists but is locked, this will block until unlocked.
    # If no document exists, does not yield.  Returns true if a document was available for modification.  False otherwise
    def modify(id)
      @caller.modify(id) do |doc|
        yield doc
      end
    end

    # Lock and enable modification of a document.  If the document exists but is locked or no document exists, does not yield.
    # Returns true if a document was available for modification.  False otherwise
    def modify!(id)
      @caller.modify!(id) do |doc|
        yield doc
      end
    end
  end
end
