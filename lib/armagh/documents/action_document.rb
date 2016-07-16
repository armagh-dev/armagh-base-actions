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

module Armagh
  module Documents
    class ActionDocument
      attr_reader :source
      attr_accessor :document_id, :docspec, :metadata, :content, :title, :copyright, :document_timestamp

      def initialize(document_id:, title: nil, copyright: nil, content:, metadata:, docspec:, source:, document_timestamp: nil, new: false)
        @document_id = document_id.freeze
        @title = title
        @copyright = copyright
        @content = content
        @metadata = metadata
        @docspec = docspec
        @source = source.dup.freeze
        @document_timestamp = document_timestamp
        @new = new
      end

      def new_document?
        @new
      end
    end
  end
end
