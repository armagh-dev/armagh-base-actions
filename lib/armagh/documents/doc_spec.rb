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

require_relative 'doc_state'
require_relative 'errors'

module Armagh
  module Documents
    class DocSpec
      attr_reader :type, :state

      def initialize(type, state)
        raise Errors::DocStateError, "Unknown state #{state}.  Valid states are #{Armagh::Documents::DocState::constants.collect { |c| c.to_s }}" unless DocState.valid_state?(state)
        raise Errors::DocSpecError, 'Type must be a non-empty string.' unless type.is_a?(String) && !type.empty?

        @type = type.freeze
        @state = state
      end

      def ==(other)
        @type == other.type && @state == other.state
      end

      def eql?(other)
        self == other
      end

      def hash
        to_s.hash
      end

      def to_s
        "#{type}:#{state}"
      end

      def to_hash
        {
            "type" => @type,
            "state" => @state
        }
      end
    end
  end
end