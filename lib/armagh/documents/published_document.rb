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
require_relative 'action_document'

module Armagh
  module Documents
    class PublishedDocument < ActionDocument
      # Metadata is fine
      def source
        protect @source
      end

      def source=(_v)
        raise Errors::DocumentError, 'Source can not be set on an already published document.'
      end

      def content
        protect @content
      end

      def content=(_v)
        raise Errors::DocumentError, 'Content can not be set on an already published document.'
      end

      def document_id
        protect @document_id
      end

      def document_id=(document_id)
        raise Errors::DocumentError, 'Document_id can not be set on an already published document.'
      end

      def title
        protect @title
      end

      def title=(_v)
        raise Errors::DocumentError, 'Title can not be set on an already published document.'
      end

      def copyright
        protect @copyright
      end

      def copyright=(_v)
        raise Errors::DocumentError, 'Copyright can not be set on an already published document.'
      end

      def docspec=(_v)
        raise Errors::DocumentError, 'Docspec can not be set on an already published document.'
      end

      def document_timestamp=(_v)
        raise Errors::DocumentError, 'Document_timestamp can not be set on an already published document.'
      end

      private def protect(item)
        item.dup.freeze
      end
    end
  end
end
