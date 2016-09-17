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
    class Source
      attr_accessor :type, :filename, :path, :host, :mtime, :url, :encoding, :mime_type

      def initialize(type: nil, filename: nil, path: nil, host: nil, mtime: nil, url: nil, encoding: nil, mime_type: nil)
        @type = type
        @filename = filename
        @path = path
        @host = host
        @mtime = mtime
        @url = url
        @encoding = encoding
        @mime_type = mime_type
      end

      def ==(other)
        to_hash == other.to_hash
      end

      def eql?(other)
        self == other
      end

      def to_hash
        h = {}
        instance_variables.each { |v| h[v[1..-1]] = instance_variable_get(v) }
        h
      end

      def self.from_hash(hash)
        s = new()
        hash.each do |k, v|
          k = :"@#{k}"
          s.instance_variable_set(k, v) if s.instance_variable_defined?(k)
        end
        s
      end
    end
  end
end
