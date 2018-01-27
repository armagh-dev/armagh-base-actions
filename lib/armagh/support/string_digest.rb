# Copyright 2018 Noragh Analytics, Inc.
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

require 'digest'

module Armagh
  module Support
    module StringDigest

      module_function

        class StringDigestError < StandardError; end
        class StringValueError < StringDigestError; end

      def md5(str)
        raise StringDigest::StringValueError, 'Input must be a string' unless str.is_a? String
        raise StringDigest::StringValueError, 'Input must not be empty' if str.empty?
        digest = Digest::MD5.base64digest(str)
        digest.gsub!(/[+\/=]/,'')
        digest
      end

    end
  end
end
