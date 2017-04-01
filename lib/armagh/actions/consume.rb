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

require_relative 'action'
require 'configh'

module Armagh
  module Actions
    class Consume < Action
      # Triggered by a Doctype in a Published state.  The incoming document is unchanged.
      # Can create/edit additional documents of any type or state
      
      include Configh::Configurable
      define_group_validation_callback callback_class: Consume, callback_method: :report_validation_errors

      VALID_INPUT_STATE = Documents::DocState::PUBLISHED
      VALID_OUTPUT_STATES = [nil, Documents::DocState::READY, Documents::DocState::WORKING].freeze

      def self.inherited( base )
        base.register_action
      end

      # Doc is an PublishedDocument
      def consume(doc)
        raise Errors::ActionMethodNotImplemented, 'Consume actions must overwrite the consume method.'
      end

      # raises InvalidDoctypeError
      def edit(id = random_id, docspec_name)
        docspec_param = @config.find_all_parameters{ |p| p.group == 'output' && p.name == docspec_name }.first
        docspec = docspec_param&.value
        raise Documents::Errors::DocSpecError.new "Editing an unknown docspec #{docspec_name}. " if docspec.nil?
        @caller.edit_document(id, docspec) do |external_doc|
          yield external_doc
        end
      end

      def Consume.report_validation_errors( candidate_config )
        errors = []
        docspec_errors = validate_docspecs(candidate_config)
        errors.concat docspec_errors
        errors.empty? ? nil : errors.join(', ')
      end
    end
  end
end
