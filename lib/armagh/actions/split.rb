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

require_relative 'action'

module Armagh
  module Actions
    class Split < Action
      # Triggered by DocType:ready
      # Doc is deleted after the split is complete
      # Can create/edit additional documents of any type or state
      include Configh::Configurable
      define_group_validation_callback callback_class: Split, callback_method: :report_validation_errors
    
      def self.inherited( base )
        base.register_action
      end
      
      # Doc is an ActionDocument
      def split(doc)
        raise Errors::ActionMethodNotImplemented, 'Split actions must overwrite the split method.'
      end

      def edit(id = random_id, docspec_name)
        docspec_param = @config.find_all_parameters{ |p| p.group == 'output' and p.name == docspec_name }.first
        docspec = docspec_param&.value
        raise Documents::Errors::DocSpecError.new "Editing an unknown docspec #{docspec_name}." if docspec.nil?

        @caller.edit_document(id, docspec) do |external_doc|
          yield external_doc
        end
      end

      def Split.report_validation_errors( candidate_config )

        errors = []
        valid_states = [Documents::DocState::READY, Documents::DocState::WORKING]
        candidate_config.find_all_parameters{ |p| p.group == 'output' }.each do |docspec_param|
          errors << "Output docspec '#{docspec_param.name}' state must be one of: #{valid_states.join(", ")}." unless valid_states.include?(docspec_param.value.state)
        end

        errors.empty? ? nil : errors.join(", ")
      end

    end
  end
end
