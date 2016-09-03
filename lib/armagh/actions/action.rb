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

require 'configh'

require_relative 'encodable'
require_relative 'loggable'
require_relative 'errors'
require_relative '../documents'

module Armagh
  module Actions
    
    class ActionError < StandardError; end
    # TODO base actions lib/armagh/actions/action.rb - Add a deduplication by action instance (string)
    # TODO base actions lib/armagh/actions/action.rb - Add a deduplication configuration for time to live per action instance

    class Action
      attr_reader :name, :config

      include Loggable
      include Encodable
      include Configh::Configurable
      
      define_parameter name: 'name',    type: 'populated_string', required: true, description: 'Name of this action configuration', prompt: 'ComtexCollectAction', group: 'action'
      define_parameter name: 'active',  type: 'boolean',          required: true, description: 'Agents will run this configuration if active', default: false
      define_group_validation_callback callback_class: Action, callback_method: :report_validation_errors
      
      def self.inherited( base )
        base.define_parameter name: 'docspec', type: 'docspec', required: true, description: 'Input doctype for this action', group: 'input'
      
        base.define_singleton_method( :define_default_input_type ){ |args| 
          default_type, description = args
          description ||= 'The type of document this action accepts'
          define_parameter name: "docspec", type: 'docspec', required: true, description: description, 
                           default: Documents::DocSpec.new( default_type, Documents::DocState::READY ), group: 'input'          
        }
      end
      
      def initialize(caller_instance, logger_name, config)
        
        Action.validate_action_type( self.class )
        @config = config
        @caller = caller_instance
        @logger_name = logger_name
      end

      def self.define_output_docspec(name, description, default_type: nil, default_state: nil)
        
        parameter_specs = { name: name, type: 'docspec', description: description, required: true, group: 'output'}
        
        if default_type || default_state
          docspec_errors = Documents::DocSpec.report_validation_errors( default_type, default_state ) 
          raise Configh::ParameterDefinitionError, "#{name} output document spec: #{ docspec_errors }" if docspec_errors
          parameter_specs[ :default ] = Documents::DocSpec.new( default_type, default_state )
        end

        define_parameter parameter_specs
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
        configured_output_docspecs = candidate_config.find_all{ |p| p.group == 'output' and p.type == 'docspec' }.collect{ |p| p.value }
        if configured_output_docspecs.include?( candidate_config.input.docspec )
          return "Action can't have same doc specs as input and output"
        else
          return nil
        end
      end
      
    end
  end
end
