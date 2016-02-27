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

require 'securerandom'

require_relative 'action'

module Armagh
  class CollectAction < Action

    # Doc is an ActionDocument
    def collect
      raise ActionErrors::ActionMethodNotImplemented.new 'CollectActions must overwrite the collect method.'
    end

    # Collected can either be a string or a filename
    # raises ActionErrors::DoctypeError
    def create(id = nil, collected, meta, doctype_name)
      doctype = @output_doctypes[doctype_name]
      raise ActionErrors::DoctypeError.new "Creating an unknown doctype #{doctype_name}.  Available doctypes are #{@output_doctypes.keys}" if doctype.nil?

      splitter = @caller.get_splitter(@name, doctype_name)

      if splitter
        if File.file? collected
          collected_file = collected
        else
          collected_file = SecureRandom.uuid
          File.write(collected_file, collected)
        end

        collected_doc = CollectedDocument.new(id, collected_file, meta, doctype)
        splitter.split(collected_doc)
      else
        content = File.file?(collected) ? File.read(collected_file) : collected
        action_doc = ActionDocument.new(id, content, {}, meta, doctype)
        @caller.create_document(action_doc)
      end
    end

    def valid?
      valid = true
      valid &&= super

      @input_doctypes.each do |name, doctype|
        unless [DocState::READY, DocState::WORKING].include?(doctype.state)
          valid = false
          @validation_errors['input_doctypes'] ||= {}
          @validation_errors['input_doctypes'][name] = "Input document state for a CollectAction must be #{DocState::READY} or #{DocState::WORKING}."
        end
      end

      @output_doctypes.each do |name, doctype|
        unless [DocState::READY, DocState::WORKING].include?(doctype.state)
          valid = false
          @validation_errors['output_doctypes'] ||= {}
          @validation_errors['output_doctypes'][name] = "Output document state for a CollectAction must be #{DocState::READY} or #{DocState::WORKING}."
        end
      end
      valid
    end
  end
end
