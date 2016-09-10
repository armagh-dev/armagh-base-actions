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
require_relative 'doc_state'
require_relative 'errors'

module Configh
  module DataTypes
    
    def DataTypes.ensure_is_docspec( value )
      raise TypeError, "value #{value} is not a docspec" unless value.is_a?( Armagh::Documents::DocSpec )
      value
    end
  end
end

module Armagh
  module Documents
    class DocSpec
      attr_reader :type, :state
      
      BSON_TYPE = 130.chr.force_encoding('binary').freeze
      BSON::Registry.register BSON_TYPE, self
      
      def self.report_validation_errors( type, state )
        errors = []
        errors << "Unknown state #{state}.  Valid states are #{Armagh::Documents::DocState::constants.collect { |c| c.to_s }.join(", ")}" unless DocState.valid_state?(state)
        errors << 'Type must be a non-empty string.' unless type.is_a?(String) && !type.empty?
        errors.empty? ? nil : errors.join(", ")
      end  

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
      
      def self.from_bson( buffer )
        type, state = BSON::Array.from_bson( buffer )
        new( type, state )
      end
      
      def to_bson( buffer )
        BSON::Array.new( [ type, state ] ).to_bson
      end
              
    end
  end
end