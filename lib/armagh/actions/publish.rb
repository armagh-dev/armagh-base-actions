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

require_relative 'action'

module Armagh
  module Actions
    class Publish < Action
      # Triggered by DocType:ready
      # Content within doc is committed to a finalized state of the document
      # Can create/edit additional documents of any type or state
      
      include Configh::Configurable
      define_group_validation_callback callback_class: Publish, callback_method: :report_validation_errors

      def self.inherited( base )
        base.register_action
        base.define_output_docspec 'docspec', 'the published document'

        base.define_singleton_method( :define_default_input_type ){ |*args|
          raise ConfigurationError, 'The input docspec is already defined for you in a publish action.'
        }
        
        base.define_singleton_method( :define_output_docspec) { |*args|
          raise ConfigurationError, 'The output docspec is already defined for you in a publish action.'
        }
      end
      
      # Gets the published action document
      def get_existing_published_document(doc)
        @caller.get_existing_published_document(doc)
      end

      # Doc is an ActionDocument
      def publish(doc)
        raise Actions::Errors::ActionMethodNotImplemented, 'Publish actions must overwrite the publish method.'
      end

      def Publish.report_validation_errors( candidate_config )

        valid_states = [Documents::DocState::PUBLISHED ]
        
        output_docspec_params = candidate_config.find_all_parameters{ |p| p.group == 'output' }
        docspec_param = output_docspec_params.first
        
        return "Publish actions must have exactly one output type" unless output_docspec_params.length == 1
        
        docspec_param = output_docspec_params.first
        output_doctype = docspec_param.value.type
        
        unless output_doctype == candidate_config.input.docspec.type
          return "Input doctype (#{candidate_config.input.docspec.type}) and output doctype (#{output_doctype}) must be the same"
        end
        
        return "Output document state for a Publish action must be published." unless valid_states.include?(docspec_param.value.state)
        
        return nil
       end
     end
  end
end
