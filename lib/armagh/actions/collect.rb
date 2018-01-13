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
require_relative '../support/decompress'
require_relative '../support/extract'

module Armagh
  module Actions

    class Collect < Action
      include Configh::Configurable

      define_parameter name: 'schedule',       type: 'string',  required: false, description: 'Schedule to run the collector.  Cron syntax.  If not set, Collect must be manually triggered.', prompt: '*/15 * * * *', group: 'collect'
      define_parameter name: 'archive',        type: 'boolean', required: true, description: 'Archive collected documents', group: 'collect', default: true
      define_parameter name: 'decompress',     type: 'boolean', required: true, description: 'Decompress (gunzip) incoming documents', group: 'collect', default: false
      define_parameter name: 'extract',        type: 'boolean', required: true, description: 'Extract incoming archive files', group: 'collect', default: false
      define_parameter name: 'extract_format', type: 'string',  required: true, default: OPTION_AUTO, description: "The extraction mechanism to use.  Selecting #{OPTION_AUTO} will automatically determine the format based on incoming filename.", group: 'collect', options: [OPTION_AUTO] + Support::Extract::TYPES
      define_parameter name: 'extract_filter', type: 'string',  required: false, description: 'Only extracted files matching this filter will be processed.  If not set, all files will be processed.', prompt: '*.json', group: 'collect'

      define_group_validation_callback callback_class: Collect, callback_method: :report_validation_errors

      VALID_INPUT_STATE = Documents::DocState::READY
      VALID_OUTPUT_STATES = [Documents::DocState::READY, Documents::DocState::WORKING].freeze

      COLLECT_DOCTYPE_PREFIX = '__COLLECT__'

      def self.inherited(base)
        base.register_action
        base.define_default_input_type COLLECT_DOCTYPE_PREFIX
        base.define_output_docspec 'docspec', 'The docspec of the default output from this action'

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
      def create(document_id: nil, title: nil, copyright: nil, document_timestamp: nil, collected:, metadata:, docspec_name: 'docspec', source:)
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

        archive_data = {
          'source' => source.to_hash,
          'document_id' => document_id,
          'title' => title,
          'copyright' => copyright,
          'document_timestamp' => document_timestamp,
          'metadata' => metadata
        }
        archive_data.delete_if{|_k, v| v.nil?}

        divider = @caller.instantiate_divider(docspec)

        extract_format = @config.collect.extract_format == OPTION_AUTO ? nil : @config.collect.extract_format

        if divider
          docspec_param = divider.config.find_all_parameters { |p| p.group == 'output' && p.name == docspec_name }.first
          docspec = docspec_param&.value
          collected_content = nil

          begin
            if File.file? collected
              collected_file = collected
            else
              collected_content = collected
              collected_file = random_id
              File.write(collected_file, collected_content)
            end
          rescue ArgumentError
            collected_content = collected
            collected_file = random_id
            File.write(collected_file, collected_content)
          end

          @caller.archive(@logger_name, @name, collected_file, archive_data) if @config.collect.archive

          if @config.collect.decompress
            collected_content ||= File.read(collected_file)
            collected_content = Support::Decompress.decompress(collected_content)
            File.write(collected_file, collected_content)
          end

          divider.doc_details = {
            'source' => source,
            'title' => title,
            'copyright' => copyright,
            'document_timestamp' => document_timestamp
          }

          if @config.collect.extract
            collected_content ||= File.read(collected_file)
            extracted_files = false

            Support::Extract.extract(collected_content, filename: collected_file, type: extract_format, filename_pattern: @config.collect.extract_filter) do |filename, extracted_content|
              extract_source = source.deep_copy
              extract_source.filename = "#{source.filename}:#{filename}"
              FileUtils.mkdir_p File.dirname(filename)
              File.write(filename, extracted_content)
              collected_doc = Documents::CollectedDocument.new(collected_file: filename, metadata: metadata, docspec: docspec)
              start = Time.now
              divider.divide(collected_doc)
              log_info "#{(Time.now - start).round(2)} seconds of collect were spent on #{divider.name} dividing #{extract_source.filename}."
              extracted_files = true
            end

            notify_ops 'No files were extracted.' unless extracted_files
          else
            collected_doc = Documents::CollectedDocument.new(collected_file: collected_file, metadata: metadata, docspec: docspec)
            start = Time.now
            divider.divide(collected_doc)
            log_info "#{(Time.now - start).round(2)} seconds of collect were spent on #{divider.name} dividing #{source.filename || source.url}."
          end

          divider.doc_details = nil
        else
          content = begin
            File.file?(collected) ? File.read(collected) : collected
          rescue ArgumentError
            collected
          end

          if @config.collect.archive
            collected_file = source.filename || random_id
            File.write(collected_file, content)
            @caller.archive(@logger_name, @name, collected_file, archive_data)
          end

          decompressed_content = @config.collect.decompress ? Support::Decompress.decompress(content) : content

          if @config.collect.extract
            extracted_files = false

            Support::Extract.extract(decompressed_content, filename: source.filename, type: extract_format, filename_pattern: @config.collect.extract_filter) do |filename, extracted_content|
              extract_source = source.deep_copy
              extract_source.filename = "#{source.filename}:#{filename}"

              action_doc = Documents::ActionDocument.new(document_id: document_id,
                                                         content: nil,
                                                         raw: nil,
                                                         metadata: metadata,
                                                         title: title,
                                                         copyright: copyright,
                                                         document_timestamp: document_timestamp,
                                                         docspec: docspec,
                                                         source: extract_source,
                                                         new: true)

              action_doc.raw = extracted_content
              @caller.create_document(action_doc)
              extracted_files = true
            end

            notify_ops 'No files were extracted.' unless extracted_files
          else
            action_doc = Documents::ActionDocument.new(document_id: document_id,
                                                       content: nil,
                                                       raw: nil,
                                                       metadata: metadata,
                                                       title: title,
                                                       copyright: copyright,
                                                       document_timestamp: document_timestamp,
                                                       docspec: docspec,
                                                       source: source,
                                                       new: true)

            action_doc.raw = decompressed_content
            @caller.create_document(action_doc)
          end
        end
      end

      def Collect.report_validation_errors(candidate_config)
        errors = []
        docspec_errors = validate_docspecs(candidate_config)
        errors.concat docspec_errors

        schedule = candidate_config.collect.schedule
        errors << "Schedule '#{schedule}' is not valid cron syntax." if schedule && !Support::Cron.valid_cron?(schedule)

        errors.empty? ? nil : errors.join(', ')
      end
    end
  end
end
