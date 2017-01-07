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

require_relative '../support/encoding'

module Armagh
  module Actions
    module Encodable
      # Fixes the encoding of a given object.
      # @param [Object] object A String, Hash (containing strings), or Array of strings to fix encoding
      # @return [Object] A correctly encoded version of the object
      def fix_encoding(object, proposed_encoding = nil)
        raise ArgumentError, 'Fix encoding can only be called on a String, Hash, or Array.' unless object.is_a?(String) || object.is_a?(Hash) || object.is_a?(Array)
        Support::Encoding.fix_encoding(object, proposed_encoding: proposed_encoding, logger: @caller.get_logger(@logger_name))
      end
    end
  end
end
