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

module Armagh
  module Documents
    class ActionDocument
      attr_reader :id, :published_metadata, :published_content
      attr_accessor :docspec, :draft_metadata, :draft_content

      def initialize(id:, draft_content:, published_content:, draft_metadata:, published_metadata:, docspec:, new: false)
        @id = id.freeze
        @draft_content = draft_content
        @published_content = published_content.dup.freeze unless published_content.nil?
        @draft_metadata = draft_metadata
        @published_metadata = published_metadata.dup.freeze unless published_metadata.nil?
        @docspec = docspec
        @new = new
      end

      def new_document?
        @new
      end
    end
  end
end
