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
require_relative 'doc_state'
require_relative 'errors'

module Configh
  module DataTypes

    def DataTypes.ensure_is_docspec(value)
      if value.is_a?(String)
        type, state = value.split(':')

        state_val = case state
                      when Armagh::Documents::DocState::READY
                        Armagh::Documents::DocState::READY
                      when Armagh::Documents::DocState::WORKING
                        Armagh::Documents::DocState::WORKING
                      when Armagh::Documents::DocState::PUBLISHED
                        Armagh::Documents::DocState::PUBLISHED
                      else
                        nil
                    end
        value = Armagh::Documents::DocSpec.new(type, state_val) if state_val
      end
      return value if value.is_a?(Armagh::Documents::DocSpec)
      msg =
        if value.is_a?(String)
          value.empty? ? "An empty string" : "The value '#{value}'"
        elsif value.nil?
          "A nil value"
        else
          "The value '#{value}'"
        end
      raise TypeError, msg + " cannot be cast as a docspec"
    end
  end
end

module Armagh
  module Documents
    class DocSpec
      attr_reader :type, :state

      def self.report_validation_errors(type, state)
        errors = []
        errors << "Unknown state #{state}.  Valid states are #{Armagh::Documents::DocState::constants.collect { |c| c.to_s }.sort.join(', ')}" unless DocState.valid_state?(state)
        errors << 'Type must be a non-empty string.' unless type.is_a?(String) && !type.empty?
        errors.empty? ? nil : errors.join(", ")
      end

      def initialize(type, state)
        raise Errors::DocStateError, "Unknown state #{state}.  Valid states are #{Armagh::Documents::DocState::constants.collect { |c| c.to_s }.sort.join(', ')}" unless DocState.valid_state?(state)
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
        "#{@type}:#{@state}"
      end

      def to_hash
        {
          'type' => @type,
          'state' => @state
        }
      end

      def self.from_hash(hash)
        new(hash['type'], hash['state'])
      end
    end
  end
end
