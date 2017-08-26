# Copyright 2017 Noragh Analytics, Inc.
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

require 'configh'

require_relative 'abortable'
require_relative 'encodable'
require_relative 'loggable'
require_relative 'stateful'
require_relative 'errors'
require_relative '../documents'
require_relative '../support/random'

module Armagh
  module Actions

    class ActionError < StandardError; end

    class InvalidArgumentError < ActionError
      def initialize(invalid_arg, invalid_value, expected_type)
        msg = "#{invalid_arg} argument was a #{invalid_value.class.to_s}, but should be a #{expected_type}"
        super(msg)
      end
    end

    class Action
      attr_reader :name, :config

      include Loggable
      include Encodable
      include Stateful
      include Abortable
      include Configh::Configurable

      define_group_validation_callback callback_class: Action, callback_method: :report_validation_errors

      # VALID_INPUT_STATE should be overwritten by subclass.  There can only be one.
      VALID_INPUT_STATE = nil

      # VALID_OUTPUT_STATES should be overwritten by subclass.
      VALID_OUTPUT_STATES = []

      def self.register_action

        include Configh::Configurable

        define_parameter name: 'name',    type: 'populated_string', required: true, description: 'Name of this action configuration', prompt: '<WORKFLOW-NAME>CollectAction', group: 'action'
        define_parameter name: 'active',  type: 'boolean',          required: true, description: 'Agents will run this configuration if active', default: false, group: 'action'
        define_parameter name: 'workflow', type: 'populated_string', required: false, description: 'Workflow this action config belongs to', prompt: '<WORKFLOW-NAME>', group: 'action'
        define_parameter name: 'docspec', type: 'docspec', required: true, description: 'Input doctype for this action', group: 'input'

        define_singleton_method(:define_default_input_type) { |args|
          default_type, description = args
          description ||= 'The type of document this action accepts'
          define_parameter name: "docspec", type: 'docspec', required: true, description: description,
                           default: Documents::DocSpec.new(default_type, self::VALID_INPUT_STATE), group: 'input'

        }

        define_singleton_method( :define_output_docspec ){ |name, description, **options|

          default_type = options[ :default_type ]
          default_state = options[ :default_state ]
          name ||= ''
          parameter_specs = { name: name.downcase, type: 'docspec', description: description, required: true, group: 'output'}

          if default_type || default_state
            docspec_errors = Documents::DocSpec.report_validation_errors( default_type, default_state )
            raise Configh::ParameterDefinitionError, "#{name} output document spec: #{ docspec_errors }" if docspec_errors
            parameter_specs[ :default ] = Documents::DocSpec.new( default_type, default_state )
          end

          define_parameter parameter_specs

        }
      end

      def initialize(caller_instance, logger_name, config, state_collection)

        Action.validate_action_type( self.class )
        @config = config
        @name = config.action.name
        @caller = caller_instance
        @logger_name = logger_name
        @state_collection = state_collection
      end

      def self.defined_output_docspecs
        defined_parameters.find_all{ |p| p.group == 'output' and p.type == 'docspec' }
      end

      def Action.validate_action_type( action_class )
        valid_actions = %w(Armagh::Actions::Split Armagh::Actions::Consume Armagh::Actions::Publish Armagh::Actions::Collect Armagh::Actions::Divide)
        valid_type = (action_class.ancestors.collect { |a| a.name } & valid_actions).any?
        raise ActionError, "Unknown Action Type #{name.sub('Armagh::', '')}.  Expected to be a descendant of #{valid_actions.join(", ")}." unless valid_type
      end

      def Action.report_validation_errors( candidate_config )
        errors = []
        errors.empty? ? nil : errors.join(', ')
      end

      def self.validate_docspecs(candidate_config)
        errors = []
        configured_output_docspecs = candidate_config.find_all_parameters{ |p| p.group == 'output' and p.type == 'docspec' }

        errors << 'Action must have at least one output docspec defined.' unless configured_output_docspecs.length > 0 || self::VALID_OUTPUT_STATES.include?(nil)

        configured_output_docspecs.each do |output_docspec|
          errors << "Action can't have same doc specs as input and output." if output_docspec.value == candidate_config.input.docspec
          errors << "Output docspec '#{output_docspec.name}' state must be one of: #{self::VALID_OUTPUT_STATES.compact.join(', ')}." unless self::VALID_OUTPUT_STATES.include? output_docspec.value.state
        end

        configured_input_docspecs = candidate_config.find_all_parameters{ |p| p.group == 'input' and p.type == 'docspec' }
        configured_input_docspec = configured_input_docspecs.first

        errors << 'Actions can only have one input docspec' unless configured_input_docspecs.length == 1
        errors << "Input docspec '#{configured_input_docspec.name}' state must be #{self::VALID_INPUT_STATE}." unless configured_input_docspec.value.state == self::VALID_INPUT_STATE
        errors
      end

      def self.add_action_params( name, values )
        new_values = Marshal.load( Marshal.dump( values ))
        new_values[ 'action' ] ||= {}
        new_values[ 'action' ][ 'name' ] ||= name
        new_values[ 'action' ][ 'active' ] = true unless new_values[ 'action' ].has_key?( 'active' )

        new_values
      end

      def self.create_configuration( collection, name, values, **args )
        raise Armagh::Actions::InvalidArgumentError.new("values", values, Hash) unless values.is_a?(Hash)
        raise Armagh::Actions::InvalidArgumentError.new("name", name, String) unless name.is_a?(String)

        new_values = add_action_params( name, values )
        super( collection, name, new_values, **args )
      end

      def with_locked_action_state( timeout = 10 )
        super( @state_collection, timeout )
      end

      def random_id
        Armagh::Support::Random.random_id
      end

      def self.description
        'No description available.'
      end

      def notify(errors)
        errors = Array(errors)
        errors.each { |e| e.notify(self) }
      end

    end
  end
end
