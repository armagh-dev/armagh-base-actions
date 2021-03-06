# Copyright 2018 Noragh Analytics, Inc.
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

require 'bson'

require_relative 'action'
require_relative 'encodable'
require_relative 'loggable'
require 'configh/configurable'

module Armagh
  module Actions
    class Divide < Action
      # Divides a collected document before storing for processing.  This is an optional component that runs on each document after a collect.  May be useful
      #  for dividing up work or handling files that are too large to store in Mongo.

      include Configh::Configurable

      attr_accessor :doc_details
      define_group_validation_callback callback_class: Divide, callback_method: :report_validation_errors

      VALID_INPUT_STATE = Documents::DocState::READY
      VALID_OUTPUT_STATES = [Documents::DocState::READY, Documents::DocState::WORKING].freeze

      def self.inherited(base)
        base.register_action
        base.define_output_docspec 'docspec', 'The docspec of the default output from this action'
      end

      def initialize(*args)
        super
        @doc_details = nil
      end

      # Doc is a CollectedDocument
      def divide(doc)
        raise Errors::ActionMethodNotImplemented, 'Dividers must overwrite the divide method.'
      end

      def create(content, metadata, document_id:nil, title:nil)
        docspec_param = @config.find_all_parameters { |p| p.group == 'output' && p.type == 'docspec' && p.name == 'docspec' }.first
        docspec = docspec_param&.value

        raise Errors::CreateError, "Divider metadata must be a Hash, was a #{metadata.class}." unless metadata.is_a?(Hash)

        action_doc = Documents::ActionDocument.new(document_id: document_id,
                                                   source: @doc_details['source'],
                                                   content: nil,
                                                   raw: nil,
                                                   metadata: metadata,
                                                   title: title || @doc_details['title'],
                                                   copyright: @doc_details['copyright'],
                                                   docspec: docspec,
                                                   document_timestamp: @doc_details['document_timestamp'],
                                                   new: true)
        action_doc.raw = content
        @caller.create_document(action_doc)
      end

      def self.report_validation_errors(candidate_config)
        errors = []

        docspec_errors = validate_docspecs(candidate_config)
        errors.concat docspec_errors

        output_docspec_params = candidate_config.find_all_parameters{ |p| p.group == 'output' }
        errors << 'Divide actions must have exactly one output docspec.' unless output_docspec_params.length == 1

        errors.empty? ? nil : errors.join(', ')
      end
    end
  end
end

