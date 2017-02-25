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

require 'bson'
require 'configh'

require_relative 'action'
require_relative '../support/cron'
require_relative '../support/sftp'

module Armagh
  module Actions

    class ConfigurationError < StandardError;
    end

    class Collect < Action
      include Configh::Configurable

      define_parameter name: 'schedule', type: 'string', required: true, description: 'Schedule to run the collector.  Cron syntax', prompt: '*/15 * * * *', group: 'collect'
      define_parameter name: 'archive', type: 'boolean', required: true, description: 'Archive collected documents', group: 'collect', default: true

      define_group_validation_callback callback_class: Collect, callback_method: :report_validation_errors

      COLLECT_DOCTYPE_PREFIX = '__COLLECT__'

      def self.inherited(base)
        base.register_action
        base.define_default_input_type COLLECT_DOCTYPE_PREFIX

        base.define_singleton_method(:define_default_input_type) { |*args|
          raise ConfigurationError, 'You cannot define default input types for collectors'
        }
      end

      def self.add_action_params(name, values)
        new_values = super
        new_values['input'] ||= {}
        new_values['input']['docspec'] = "#{ COLLECT_DOCTYPE_PREFIX }#{new_values['action']['name']}:#{Documents::DocState::READY}"

        new_values
      end

      # Doc is an ActionDocument
      def collect
        raise Errors::ActionMethodNotImplemented.new 'Collect actions must overwrite the collect method.'
      end

      # Collected can either be a string or a filename
      # raises ActionDocuments::Errors::DocSpecError
      def create(document_id: nil, title: nil, copyright: nil, document_timestamp: nil, collected:, metadata:, docspec_name:, source:)
        docspec_param = @config.find_all_parameters { |p| p.group == 'output' && p.name == docspec_name }.first
        docspec = docspec_param&.value
        raise Documents::Errors::DocSpecError, "Creating an unknown docspec #{docspec_name}" unless docspec
        raise Errors::CreateError, "Collect action content must be a String, was a #{collected.class}." unless collected.is_a?(String)
        raise Errors::CreateError, "Collect action source must be a Source type, was a #{source.class}." unless source.is_a?(Documents::Source)
        raise Errors::CreateError, "Collect action metadata must be a Hash, was a #{metadata.class}." unless metadata.is_a?(Hash)

        raise Errors::CreateError, "Collect action document_id must be a String, was a #{document_id.class}." unless document_id.nil? || document_id.is_a?(String)
        raise Errors::CreateError, "Collect action title must be a String, was a #{title.class}." unless title.nil? || title.is_a?(String)
        raise Errors::CreateError, "Collect action copyright must be a String, was a #{copyright.class}." unless copyright.nil? || copyright.is_a?(String)
        raise Errors::CreateError, "Collect action document_timestamp must be a Time, was a #{document_timestamp.class}." unless document_timestamp.nil? || document_timestamp.is_a?(Time)

        case source.type
          when 'file'
            raise Errors::CreateError, 'Source filename must be set.' unless source.filename.is_a?(String) && !source.filename.empty?
            raise Errors::CreateError, 'Source host must be set.' unless source.host.is_a?(String) && !source.host.empty?
            raise Errors::CreateError, 'Source path must be set.' unless source.path.is_a?(String) && !source.path.empty?
          when 'url'
            raise Errors::CreateError, 'Source url must be set.' unless source.url.is_a?(String) && !source.url.empty?
          else
            raise Errors::CreateError, 'Source type must be url or file.'
        end

        divider = @caller.instantiate_divider(docspec)

        if divider
          docspec_param = divider.config.find_all_parameters { |p| p.group == 'output' && p.name == docspec_name }.first
          docspec = docspec_param&.value

          if File.file? collected
            collected_file = collected
          else
            collected_file = random_id
            File.write(collected_file, collected)
          end

          collected_doc = Documents::CollectedDocument.new(collected_file: collected_file, metadata: metadata, docspec: docspec)
          divider.doc_details = {
            'source' => source,
            'document_id' => document_id,
            'title' => title,
            'copyright' => copyright,
            'document_timestamp' => document_timestamp
          }

          if @config.collect.archive
            archive_data = {
              'source' => source.to_hash,
              'document_id' => document_id,
              'title' => title,
              'copyright' => copyright,
              'document_timestamp' => document_timestamp,
              'metadata' => metadata
            }
            archive_data.delete_if{|_k, v| v.nil?}

            @caller.archive(@logger_name, @name, collected_file, archive_data)
          end

          divider.divide(collected_doc)
          divider.doc_details = nil
        else
          content = File.file?(collected) ? File.read(collected) : collected

          action_doc = Documents::ActionDocument.new(document_id: document_id,
                                                     content: nil,
                                                     metadata: metadata,
                                                     title: title,
                                                     copyright: copyright,
                                                     document_timestamp: document_timestamp,
                                                     docspec: docspec,
                                                     source: source,
                                                     new: true)
          action_doc.raw = content

          if @config.collect.archive
            collected_file = source.filename || random_id
            File.write(collected_file, content)
            @caller.archive(@logger_name, @name, collected_file, action_doc.to_archive_hash)
          end

          @caller.create_document(action_doc)
        end
      end

      def Collect.report_validation_errors(candidate_config)

        errors = []
        output_docspec_defined = false
        valid_states = [Documents::DocState::READY, Documents::DocState::WORKING]
        
        candidate_config.find_all_parameters { |p| p.group == 'output' }.each do |docspec_param|
          output_docspec_defined = true
          errors << "Output docspec '#{docspec_param.name}' state must be one of: #{valid_states.join(", ")}." unless valid_states.include?(docspec_param.value.state)
        end

        errors << "Collect actions must have at least one output docspec defined in the class" unless output_docspec_defined
        
        schedule = candidate_config.collect.schedule
        errors << "Schedule '#{schedule}' is not valid cron syntax." unless Support::Cron.valid_cron?(schedule)

        if candidate_config.collect.archive
          begin
            Support::SFTP.archive_config
          rescue => e
            errors << "Archive Configuration Error: #{e}"
          end
        end

        errors.empty? ? nil : errors.join(', ')
      end
    end
  end
end
