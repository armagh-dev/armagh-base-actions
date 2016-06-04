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

require_relative 'parameterized'
require_relative 'errors'
require_relative '../documents'

module Armagh
  module Actions
    # TODO base actions lib/armagh/actions/action.rb - Add a deduplication by action instance (string)
    # TODO base actions lib/armagh/actions/action.rb - Add a deduplication configuration for time to live per action instance

    class Action < Parameterized
      attr_reader :output_docspecs, :name

      def initialize(name, caller_instance, logger, parameters, output_docspecs)
        super(parameters)
        @name = name
        @caller = caller_instance
        @logger = logger
        @output_docspecs = output_docspecs
      end

      def self.define_input_type(default_type)
        raise Documents::Errors::DocSpecError, "Default type is already defined as #{@defined_input_type}." unless @defined_input_type.nil?
        raise Documents::Errors::DocSpecError, "Default type #{default_type} must be a String." unless default_type.is_a? String
        @defined_input_type = default_type
      end

      def self.defined_input_type
        @defined_input_type
      end

      def self.define_output_docspec(name, default_type: nil, default_state: nil)
        raise Documents::Errors::DocSpecError, 'Output DocSpec name must be a String.' unless name.is_a? String
        raise Documents::Errors::DocSpecError, "Output DocSpec #{name}'s default_type must be a String." unless default_type.nil? || default_type.is_a?(String)
        raise Documents::Errors::DocSpecError, "Output DocSpec #{name}'s default_state is invalid." unless default_state.nil? || Documents::DocState.valid_state?(default_state)

        defined_output_docspecs[name] = {'default_type' => default_type, 'default_state' => default_state}
      end

      def self.defined_output_docspecs
        @defined_output_docspecs ||= {}
      end

      def validate
        validate_action_type

        {'valid' => @validation_errors.empty?, 'errors' => @validation_errors, 'warnings' => @validation_warnings}
      end

      def custom_validation
        # Default has no Action level validation
        nil
      end

      private def validate_action_type
        valid_actions = %w(Armagh::Actions::Parse Armagh::Actions::Consume Armagh::Actions::Publish Armagh::Actions::Collect)
        valid_type = (self.class.ancestors.collect { |a| a.name } & valid_actions).any?
        @validation_errors << "Unknown Action Type #{self.class.to_s.sub('Armagh::', '')}.  Expected to be a descendant of #{valid_actions}." unless valid_type
      end
    end
  end
end
