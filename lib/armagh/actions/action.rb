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
require_relative '../action_errors'
require_relative '../documents'

module Armagh
  # TODO Add a deduplication by action instance (string)
  # TODO Add a deduplication configuration for time to live per action instance

  class Action < Parameterized
    attr_reader :validation_errors, :input_doctypes, :output_doctypes, :name

    def initialize(name, caller, logger, parameters, input_doctypes, output_doctypes)
      super(parameters)
      @name = name
      @caller = caller
      @logger = logger
      @input_doctypes = input_doctypes
      @output_doctypes = output_doctypes
    end

    def self.define_input_doctype(name, default_type: nil, default_state: nil)
      raise ActionErrors::DoctypeError.new 'Input Doctype name must be a String.' unless name.is_a? String
      raise ActionErrors::DoctypeError.new "Input Doctype #{name}'s default_type must be a String." unless default_type.nil? ||  default_type.is_a?(String)
      raise ActionErrors::DoctypeError.new "Input Doctype #{name}'s default_state is invalid." unless default_state.nil? ||  DocState.valid_state?(default_state)

      defined_input_doctypes[name] = {'default_type' => default_type, 'default_state' => default_state}
    end

    def self.defined_input_doctypes
      @defined_input_doctypes ||= {}
    end

    def self.define_output_doctype(name, default_type: nil, default_state: nil)
      raise ActionErrors::DoctypeError.new 'Output Doctype name must be a String.' unless name.is_a? String
      raise ActionErrors::DoctypeError.new "Output Doctype #{name}'s default_type must be a String." unless default_type.nil? ||  default_type.is_a?(String)
      raise ActionErrors::DoctypeError.new "Output Doctype #{name}'s default_state is invalid." unless default_state.nil? ||  DocState.valid_state?(default_state)

      defined_output_doctypes[name] = {'default_type' => default_type, 'default_state' => default_state}
    end

    def self.defined_output_doctypes
      @defined_output_doctypes ||= {}
    end

    def valid?
      valid = true
      valid &&= valid_action_type?
      valid
    end

    def validate
      # Default has no Action level validation
      nil
    end

    private def valid_action_type?
      valid_actions = %w(Armagh::ParseAction Armagh::SubscribeAction Armagh::PublishAction Armagh::CollectAction)
      valid_type = (self.class.ancestors.collect{|a| a.name} & valid_actions).any?
      @validation_errors['general'] = ["Unknown Action Type #{self.class.to_s.sub('Armagh::','')}.  Was #{self.class.superclass} but expected #{valid_actions}."] unless valid_type
      valid_type
    end
  end
end
