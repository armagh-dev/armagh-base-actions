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
require 'configh'

require_relative 'action'

module Armagh
  module Actions
    
    class ConfigurationError < StandardError; end
    
    class Collect < Action
      include Configh::Configurable
      
      def self.inherited( base )
        base.register_action
        base.define_default_input_type "__COLLECT__#{ base.name }"
        
        base.define_singleton_method( :define_default_input_type ){ |*args|
          raise ConfigurationError, "You cannot define default input types for collectors"
        }
      end
      
      define_group_validation_callback callback_class: Collect, callback_method: :report_validation_errors
        
      # Doc is an ActionDocument
      def collect
        raise Errors::ActionMethodNotImplemented.new 'Collect actions must overwrite the collect method.'
      end

      # Collected can either be a string or a filename
      # raises ActionDocuments::Errors::DocSpecError
      def create(collected, metadata, docspec_name, source)
        
        docspec_param = @config.find_all_parameters{ |p| p.group == 'output' && p.name == docspec_name }.first
        docspec = docspec_param&.value
        raise Documents::Errors::DocSpecError, "Creating an unknown docspec #{docspec_name}" unless docspec
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

        divider = @caller.get_divider(@config.action.name, docspec_name)

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

      def Collect.report_validation_errors( candidate_config )

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
