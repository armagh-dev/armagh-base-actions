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
    # raises ActionErrors::DocSpecError
    def create(id = nil, collected, meta, docspec_name)
      docspec = @output_docspecs[docspec_name]
      raise ActionErrors::DocSpecError, "Creating an unknown docspec #{docspec_name}.  Available docspecs are #{@output_docspecs.keys}" if docspec.nil?
      raise ActionErrors::CreateError, "Collect action content must be a String, was a #{collected.class}." unless collected.is_a?(String)

      splitter = @caller.get_splitter(@name, docspec_name)

      if splitter
        if File.file? collected
          collected_file = collected
        else
          collected_file = SecureRandom.uuid
          File.write(collected_file, collected)
        end

        collected_doc = CollectedDocument.new(id, collected_file, meta, docspec)
        splitter.split(collected_doc)
      else
        content = File.file?(collected) ? File.read(collected_file) : collected
        action_doc = ActionDocument.new(id, content, {}, meta, docspec)
        @caller.create_document(action_doc)
      end
    end

    def valid?
      valid = true
      valid &&= super

      @output_docspecs.each do |name, docspec|
        unless [DocState::READY, DocState::WORKING].include?(docspec.state)
          valid = false
          @validation_errors['output_docspecs'] ||= {}
          @validation_errors['output_docspecs'][name] = "Output document state for a CollectAction must be #{DocState::READY} or #{DocState::WORKING}."
        end
      end
      valid
    end
  end
end
