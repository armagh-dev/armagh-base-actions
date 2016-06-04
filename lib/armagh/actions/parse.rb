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
    class Parse < Action
      # Triggered by DocType:ready
      # Doc is deleted after the parse is complete
      # Can create/edit additional documents of any type or state

      # Doc is an ActionDocument
      def parse(doc)
        raise Errors::ActionMethodNotImplemented, 'ParseActions must overwrite the parse method.'
      end

      # raises InvalidDoctypeError

      def edit(id, docspec_name)
        docspec = @output_docspecs[docspec_name]
        raise Documents::Errors::DocSpecError.new "Editing an unknown docspec #{docspec_name}.  Available docspecs are #{@output_docspecs.keys}" if docspec.nil?

        @caller.edit_document(id, docspec) do |external_doc|
          yield external_doc
        end
      end

      def validate
        super

        valid_states = [Documents::DocState::READY, Documents::DocState::WORKING]
        @output_docspecs.each do |name, docspec|
          @validation_errors << "Output docspec '#{name}' state must be one of: #{valid_states}." unless valid_states.include?(docspec.state)
        end

        {'valid' => @validation_errors.empty?, 'errors' => @validation_errors, 'warnings' => @validation_warnings}
      end
    end
  end
end