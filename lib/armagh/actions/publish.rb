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

      def self.define_input_type(input_type)
        raise Documents::Errors::DocSpecError.new 'Publish actions have no usable Input doc types.'
      end

      def self.define_output_docspec(name, default_type: nil, default_state: nil)
        raise Documents::Errors::DocSpecError.new 'Publish actions have no usable Output DocSpecs.'
      end

      # Gets the published action document
      def get_existing_published_document(doc)
        @caller.get_existing_published_document(doc)
      end

      # Doc is an ActionDocument
      def publish(doc)
        raise Actions::Errors::ActionMethodNotImplemented, 'Publish actions must overwrite the publish method.'
      end

      def validate
        super
        @validation_errors << 'Publish actions can only have one output docspec.' unless @output_docspecs.length == 1

        output = @output_docspecs.first

        if output && output.last.state != Documents::DocState::PUBLISHED
          @validation_errors << "Output document state for a Publish action must be #{Documents::DocState::PUBLISHED}."
        end

        {'valid' => @validation_errors.empty?, 'errors' => @validation_errors, 'warnings' => @validation_warnings}
      end
    end
  end
end
