# Copyright 2018 Noragh Analytics, Inc.
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

require_relative 'errors'
require_relative 'doc_spec'
require_relative 'source'
require_relative 'doc_spec'

require 'json'
require 'bson'

module Armagh
  module Documents
    class ActionDocument
      attr_reader :document_id, :source, :content, :raw, :metadata, :title, :copyright, :docspec, :document_timestamp, :version, :display

      RAW_MAX_LENGTH_MB = 4
      RAW_MAX_LENGTH = RAW_MAX_LENGTH_MB * 1_048_576

      def initialize(document_id:, title:, copyright:, content:, raw:, metadata:, docspec:, source:, document_timestamp:, version: nil, display: nil, new: false)
        # Not checking the types here for 2 reasons - PublishDocument extends this while overwriting setters and custom actions dont create their own action documents.
        @document_id = document_id
        @title = title
        @copyright = copyright
        @content = content
        @raw = raw.nil? ? raw : BSON::Binary.new(raw)
        @metadata = metadata
        @docspec = docspec
        @source = source
        @document_timestamp = document_timestamp
        @version = version
        @display = display
        @new = new ? true : false
      end

      def new_document?
        @new
      end

      def validate
        validate_document_id(@document_id)
        validate_title(@title)
        validate_copyright(@copyright)
        validate_content(@content)
        validate_metadata(@metadata)
        validate_docspec(@docspec)
        validate_source(@source)
        validate_document_timestamp(@document_timestamp)
        validate_version(@version)
        validate_display(@display)
      end

      def document_id=(document_id)
        validate_document_id(document_id)
        @document_id = document_id.dup.freeze
      end

      def metadata=(metadata)
        validate_metadata(metadata)
        @metadata = metadata
      end

      def content=(content)
        validate_content(content)
        @content = content
      end

      def title=(title)
        validate_title(title)
        @title = title
      end

      def copyright=(copyright)
        validate_copyright(copyright)
        @copyright = copyright
      end

      def docspec=(docspec)
        validate_docspec(docspec)
        @docspec = docspec
      end

      def document_timestamp=(document_timestamp)
        validate_document_timestamp(document_timestamp)
        @document_timestamp = document_timestamp
      end

      def version=(version)
        validate_version(version)
        @version = version
      end

      def display=(display)
        validate_display(display)
        @display = display
      end

      def text
        content['text_content']
      end

      def text=(text)
        raise TypeError, "Value for 'text' argument expected to be a string." unless text.is_a? String

        content.nil? ? self.content = {} : content.clear
        content['text_content'] = text
      end

      def raw
        @raw&.data
      end

      def raw=(raw_data)
        binary = case raw_data
                 when String
                   BSON::Binary.new(raw_data)
                 when BSON::Binary, NilClass
                   raw_data
                 else
                   raise TypeError, 'Value for raw expected to be a string.'
                 end

        length = binary.nil? ? 0 : binary.to_bson.length
        raise Errors::DocumentRawSizeError, "Raw exceeds the maximum size of #{RAW_MAX_LENGTH_MB} MB.  Consider using a splitter or divider to reduce the size." if length > RAW_MAX_LENGTH
        @raw = binary
      end

      def to_hash
        {
            'document_id' => @document_id,
            'title' => @title,
            'copyright' => @copyright,
            'content' => @content,
            # ARM-549: raw omitted intentionally
            'metadata' => @metadata,
            'docspec' => @docspec.to_hash,
            'source' => @source.to_hash,
            'document_timestamp' => @document_timestamp,
            'version' => @version,
            'display' => @display
        }
      end

      def to_json
        to_hash.to_json
      end

      def self.from_json(json_text)
        hash = JSON.parse(json_text)
        hash['document_timestamp'] = Time.parse(hash['document_timestamp']).utc if hash['document_timestamp'].is_a? String
        from_hash(hash)
      end

      def self.from_hash(hash)
        doc = new(document_id: hash['document_id'],
            title: hash['title'],
            copyright: hash['copyright'],
            content: hash['content'],
            raw: hash['raw'],
            metadata: hash['metadata'],
            docspec: DocSpec.from_hash(hash['docspec']),
            source: Source.from_hash(hash['source']),
            document_timestamp: hash['document_timestamp'],
            version: hash['version'],
            display: hash['display']
        )
        doc.validate
        doc
      end

      private def validate_document_id(document_id)
        raise TypeError, 'Document id expected to be a string.' unless document_id.is_a? String
      end

      private def validate_title(title)
        raise TypeError, 'Title expected to be a string.' unless title.nil? || title.is_a?(String)
      end

      private def validate_copyright(copyright)
        raise TypeError, 'Copyright expected to be a string.' unless copyright.nil? || copyright.is_a?(String)
      end

      private def validate_content(content)
        raise TypeError, 'Content expected to be a hash.' unless content.is_a? Hash
      end

      private def validate_metadata(metadata)
        raise TypeError, 'Metadata expected to be a hash.' unless metadata.is_a? Hash
      end

      private def validate_docspec(docspec)
        raise TypeError, 'Docspec expected to be a DocSpec.' unless docspec.is_a? DocSpec
      end

      private def validate_source(source)
        raise TypeError, 'Source expected to be a Source.' unless source.is_a? Source
      end

      private def validate_document_timestamp(document_timestamp)
        raise TypeError, 'Document timestamp expected to be a Time.' unless document_timestamp.nil? || document_timestamp.is_a?(Time)
      end

      private def validate_version(version)
        raise TypeError, 'Version expected to be a positive integer.' unless version.nil? || (version.is_a?(Integer) && version.positive?)
      end

      private def validate_display(display)
        raise TypeError, 'Display expected to be a String.' unless display.nil? || display.is_a?(String)
      end

    end
  end
end
