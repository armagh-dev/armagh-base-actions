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

require 'zlib'
require 'facets/zlib'

module Armagh
  module Support
    module Decompress
      class DecompressError < StandardError; end

      def self.decompress(string)
        Zlib.decompress(string) # Provided by facets
      rescue
        raise DecompressError, 'Unable to decompress string.'
      end
    end
  end
end
