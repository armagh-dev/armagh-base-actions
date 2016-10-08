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

require_relative 'errors'
require_relative 'doc_spec'

require 'json'
require 'bson'

module Armagh
  module Documents
    class ActionDocument
      attr_reader :document_id, :source, :content, :metadata, :title, :copyright, :docspec, :document_timestamp, :display, :archive_file

      def initialize(document_id:, title: nil, copyright: nil, content:, metadata:, docspec:, source:, document_timestamp: nil, display: nil, archive_file: nil, new: false)
        # Not checking the types here for 2 reasons - PublishDocument extends this while overwriting setters and custom actions dont create their own action documents.
        @document_id = document_id
        @title = title
        @copyright = copyright
        @content = content
        @metadata = metadata
        @docspec = docspec
        @source = source
        @document_timestamp = document_timestamp
        @display = display
        @archive_file = archive_file
        @new = new ? true : false
      end

      def new_document?
        @new
      end

      def document_id=(document_id)
        raise TypeError, 'Document id expected to be a string.' unless document_id.is_a? String
        @document_id = document_id.dup.freeze
      end

      def metadata=(metadata)
        raise TypeError, 'Metadata expected to be a hash.' unless metadata.is_a? Hash
        @metadata = metadata
      end

      def content=(content)
        raise TypeError, 'Content expected to be a hash.' unless content.is_a? Hash
        @content = content
      end

      def title=(title)
        raise TypeError, 'Title expected to be a string.' unless title.nil? || title.is_a?(String)
        @title = title
      end

      def copyright=(copyright)
        raise TypeError, 'Copyright expected to be a string.' unless copyright.nil? || copyright.is_a?(String)
        @copyright = copyright
      end

      def docspec=(docspec)
        raise TypeError, 'Docspec expected to be a DocSpec.' unless docspec.is_a? DocSpec
        @docspec = docspec
      end

      def document_timestamp=(document_timestamp)
        raise TypeError, 'Document timestamp expected to be a Time.' unless document_timestamp.nil? || document_timestamp.is_a?(Time)
        @document_timestamp = document_timestamp
      end

      def display=(display)
        raise TypeError, 'Display expected to be a String.' unless display.nil? || display.is_a?(String)
        @display = display
      end

      def text
        content['text_content']
      end

      def text=(text)
        content.clear
        content['text_content'] = text
      end

      def raw
        content['bson_binary']&.data
      end

      def raw=(raw_data)
        content.clear
        content['bson_binary'] = BSON::Binary.new(raw_data)
      end

      def to_json
        {
          'document_id' => @document_id,
          'title' => @title,
          'copyright' => @copyright,
          'metadata' => @metadata,
          'content' => @content,
          'source' => @source.to_hash,
          'document_timestamp' => @document_timestamp,
          'docspec' => @docspec.to_hash,
          'display' => @display,
          'archive_file' => @archive_file
        }.to_json
      end

      alias_method :hash, :content
      alias_method :hash=, :content=
    end
  end
end
