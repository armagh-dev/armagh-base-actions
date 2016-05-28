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
    def create(id = nil, collected, metadata, docspec_name)
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

        collected_doc = CollectedDocument.new(id: id, collected_file: collected_file, metadata: metadata, docspec: docspec)
        splitter.split(collected_doc)
      else
        content = File.file?(collected) ? File.read(collected_file) : collected
        action_doc = ActionDocument.new(id: id, draft_content: content, published_content: {},
                                        draft_metadata: metadata, published_metadata: {}, docspec: docspec, new: true)
        @caller.create_document(action_doc)
      end
    end

    def validate
      super

      valid_states = [DocState::READY, DocState::WORKING]
      @output_docspecs.each do |name, docspec|
        @validation_errors << "Output docspec '#{name}' state must be one of: #{valid_states}." unless valid_states.include?(docspec.state)
      end

      {'valid' => @validation_errors.empty?, 'errors' => @validation_errors, 'warnings' => @validation_warnings}
    end
  end
end
