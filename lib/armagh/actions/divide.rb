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
require_relative 'encodable'
require_relative 'loggable'

module Armagh
  module Actions
    class Divide < Action
      # Divides a collected document before storing for processing.  This is an optional component that runs on each document after a collect.  May be useful
      #  for dividing up work or handling files that are too large to store in Mongo.

      include Loggable
      include Encodable
      include Configh::Configurable

      attr_accessor :source

      def self.inherited( base )
        base.register_action
      end

      def initialize( *args )
        super
        @source = nil
      end

      # Doc is a CollectedDocument
      def divide(doc)
        raise Errors::ActionMethodNotImplemented, 'Dividers must overwrite the divide method.'
      end

      def create(content, metadata)
        docspec_param = @config.find_all_parameters{ |p| p.group == 'output' && p.type == 'docspec' }.first
        docspec = docspec_param&.value
        raise Errors::CreateError, "Divider metadata must be a Hash, was a #{metadata.class}." unless metadata.is_a?(Hash)

        content_hash = {'bson_binary' => BSON::Binary.new(content)}
        action_doc = Documents::ActionDocument.new(document_id: SecureRandom.uuid, content: content_hash, metadata: metadata,
                                                   docspec: docspec, source: @source, new: true)
        @caller.create_document(action_doc)
      end
    end
  end
end

