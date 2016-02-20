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

require_relative 'parameterized'
require_relative '../errors'
require_relative '../documents'

module Armagh
  # TODO Add a deduplication by action instance (string)
  # TODO Add a deduplication configuration for time to live per action instance

  class Action < Parameterized
    attr_reader :validation_errors, :input_doctypes, :output_doctypes, :name

    def initialize(name, caller, logger, parameters, input_doctypes, output_doctypes)
      super()
      @name = name
      @caller = caller
      @logger = logger
      @parameters = parameters
      @input_doctypes = input_doctypes
      @output_doctypes = output_doctypes
    end

    def self.define_input_doctype(name, default_type: nil, default_state: nil)
      raise ActionErrors::DoctypeError.new "Input Doctype #{name}'s default_doctype must be a String." unless default_type.nil? ||  default_type.is_a?(String)
      raise ActionErrors::DoctypeError.new "Input Doctype #{name} has an invalid default state." unless default_state.nil? ||  DocState.valid_state?(default_state)
      raise ActionErrors::DoctypeError.new 'Publish actions have no usable Input Doctypes.' if self < PublishAction

      defined_input_doctypes[name] = {'default_doctype' => default_type, 'default_state' => default_state}
    end

    def self.defined_input_doctypes
      @defined_input_doctypes ||= {}
    end

    def self.define_output_doctype(name, default_type: nil, default_state: nil)
      raise ActionErrors::DoctypeError.new "Output Doctype #{name}'s default_doctype must be a String." unless default_type.nil? ||  default_type.is_a?(String)
      raise ActionErrors::DoctypeError.new "Output Doctype #{name} has an invalid default state." unless default_state.nil? ||  DocState.valid_state?(default_state)
      raise ActionErrors::DoctypeError.new 'Publish actions have no usable Output Doctypes.' if self < PublishAction

      defined_output_doctypes[name] = {'default_doctype' => default_type, 'default_state' => default_state}
    end

    def self.defined_output_doctypes
      @defined_output_doctypes ||= {}
    end

    def allowed_output_doctypes
      @output_doctypes.values
    end

    # TODO This can be cleaned up.
    # TODO The case should be broken into methods of each Action type (example: ParseAction should have a valid_action? defined that gets called from this).
    def valid?
      return false unless super

      valid = true

      case
        when self.is_a?(ParseAction)
          @input_doctypes.each do |name, doctype|
            unless doctype.state == DocState::READY
              valid = false
              @validation_errors['input_doctypes'] ||= {}
              @validation_errors['input_doctypes'][name] = "Input document state for a ParseAction must be #{DocState::READY}."
            end
          end

          @output_doctypes.each do |name, doctype|
            unless [DocState::READY, DocState::WORKING].include?(doctype.state)
              valid = false
              @validation_errors['output_doctypes'] ||= {}
              @validation_errors['output_doctypes'][name] = "Output document state for a ParseAction must be #{DocState::READY} or #{DocState::WORKING}."
            end
          end
        when self.is_a?(PublishAction)
          if @input_doctypes.length != 1
            valid = false
            @validation_errors['input_doctypes'] ||= {}
            @validation_errors['input_doctypes']['_all'] = 'PublishActions can only have one input doctype.'
          end

          if @output_doctypes.length != 1
            valid = false
            @validation_errors['output_doctypes'] ||= {}
            @validation_errors['output_doctypes']['_all'] = 'PublishActions can only have one output doctype.'
          end

          input = @input_doctypes.first
          output = @output_doctypes.first

          unless input.last.type == output.last.type
            valid = false
            @validation_errors['all_doctypes'] ||= []
            @validation_errors['all_doctypes'] << 'PublishActions must use the same doctype for input and output'
          end

          unless input.last.state == DocState::READY
            valid = false
            @validation_errors['input_doctypes'] ||= {}
            @validation_errors['input_doctypes'][input.first] = "Input document state for a PublishAction must be #{DocState::READY}"
          end

          unless output.last.state == DocState::PUBLISHED
            valid = false
            @validation_errors['output_doctypes'] ||= {}
            @validation_errors['output_doctypes'][output.first] = "Output document state for a PublishAction must be #{DocState::PUBLISHED}"
          end

        when self.is_a?(SubscribeAction)
          @input_doctypes.each do |name, doctype|
            unless doctype.state == DocState::PUBLISHED
              valid = false
              @validation_errors['input_doctypes'] ||= {}
              @validation_errors['input_doctypes'][name] = "Input document state for a SubscribeAction must be #{DocState::PUBLISHED}."
            end
          end

          @output_doctypes.each do |name, doctype|
            unless [DocState::READY, DocState::WORKING].include?(doctype.state)
              valid = false
              @validation_errors['output_doctypes'] ||= {}
              @validation_errors['output_doctypes'][name] = "Output document state for a SubscribeAction must be #{DocState::READY} or #{DocState::WORKING}."
            end
          end
        when self.is_a?(CollectAction)
          @input_doctypes.each do |name, doctype|
            unless [DocState::READY, DocState::WORKING].include?(doctype.state)
              valid = false
              @validation_errors['input_doctypes'] ||= {}
              @validation_errors['input_doctypes'][name] = "Input document state for a CollectAction must be #{DocState::READY} or #{DocState::WORKING}."
            end
          end

          @output_doctypes.each do |name, doctype|
            unless [DocState::READY, DocState::WORKING].include?(doctype.state)
              valid = false
              @validation_errors['output_doctypes'] ||= {}
              @validation_errors['output_doctypes'][name] = "Output document state for a CollectAction must be #{DocState::READY} or #{DocState::WORKING}."
            end
          end
        else
          valid = false
          @validation_errors['general'] = ["Unknown Action Type #{self.class.to_s.sub('Armagh::','')}.  Was a #{self.class.superclass.to_s.sub('Armagh::','')} but expected ParseAction, SubscribeAction, PublishAction, CollectAction, or CollectionSplitterAction."]
      end

      return false unless valid

      valid
    end

    def validate
      # Default has no Action level validation
      nil
    end
  end
end
