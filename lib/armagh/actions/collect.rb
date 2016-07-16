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

require 'bson'
require 'securerandom'

require_relative 'action'

module Armagh
  module Actions
    class Collect < Action

      # Doc is an ActionDocument
      def collect
        raise Errors::ActionMethodNotImplemented.new 'Collect actions must overwrite the collect method.'
      end

      # Collected can either be a string or a filename
      # raises ActionDocuments::Errors::DocSpecError
      def create(collected, metadata, docspec_name, source)
        docspec = @output_docspecs[docspec_name]
        raise Documents::Errors::DocSpecError, "Creating an unknown docspec #{docspec_name}.  Available docspecs are #{@output_docspecs.keys}" if docspec.nil?
        raise Errors::CreateError, "Collect action content must be a String, was a #{collected.class}." unless collected.is_a?(String)
        raise Errors::CreateError, "Collect action source must be a Hash, was a #{source.class}." unless source.is_a?(Hash)
        raise Errors::CreateError, "Collect action metadata must be a Hash, was a #{metadata.class}." unless metadata.is_a?(Hash)

        case source['type']
          when 'file'
            raise Errors::CreateError, 'Source filename must be set.' unless source['filename'].is_a?(String) && !source['filename'].empty?
            raise Errors::CreateError, 'Source host must be set.' unless source['host'].is_a?(String) && !source['host'].empty?
            raise Errors::CreateError, 'Source path must be set.' unless source['path'].is_a?(String) && !source['path'].empty?
          when 'url'
            raise Errors::CreateError, 'Source url must be set.' unless source['url'].is_a?(String) && !source['url'].empty?
          else
            raise Errors::CreateError, 'Source type must be url or file.'
        end

        divider = @caller.get_divider(@name, docspec_name)

        if divider
          if File.file? collected
            collected_file = collected
          else
            collected_file = SecureRandom.uuid
            File.write(collected_file, collected)
          end

          collected_doc = Documents::CollectedDocument.new(collected_file: collected_file, metadata: metadata, docspec: docspec)
          divider.source = source
          divider.divide(collected_doc)
          divider.source = nil
        else
          content = File.file?(collected) ? File.read(collected) : collected
          content_hash = {'bson_binary' => BSON::Binary.new(content)}
          action_doc = Documents::ActionDocument.new(document_id: SecureRandom.uuid, content: content_hash, metadata: metadata,
                                                     docspec: docspec, source: source, new: true)
          @caller.create_document(action_doc)
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
