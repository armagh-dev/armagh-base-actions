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
  class ParseAction < Action
    # Triggered by DocType:ready
    # Doc is deleted after the parse is complete
    # Can create/edit additional documents of any type or state

    # Doc is an ActionDocument
    def parse(doc)
      raise ActionErrors::ActionMethodNotImplemented, 'ParseActions must overwrite the parse method.'
    end

    # raises InvalidDoctypeError

    def edit(id, doctype_name)
      doctype = @output_doctypes[doctype_name]
      raise ActionErrors::DoctypeError.new "Editing an unknown doctype #{doctype_name}.  Available doctypes are #{@output_doctypes.keys}" if doctype.nil?

      @caller.edit_document(id, doctype) do |external_doc|
        yield external_doc
      end
    end

    def valid?
      valid = true
      valid &&= super

      @input_doctypes.each do |name, doctype|
        unless doctype.state == DocState::READY
          valid = false
          @validation_errors['input_doctypes'] ||= {}
          @validation_errors['input_doctypes'][name] = "Input document state for a ParseAction must be #{DocState::READY}."
        end
      end

      @output_doctypes.each do |name, doctype|
        unless [DocState::READY, DocState::WORKING].include?(doctype.state)
          valid = false
          @validation_errors['output_doctypes'] ||= {}
          @validation_errors['output_doctypes'][name] = "Output document state for a ParseAction must be #{DocState::READY} or #{DocState::WORKING}."
        end
      end
      valid
    end
  end
end