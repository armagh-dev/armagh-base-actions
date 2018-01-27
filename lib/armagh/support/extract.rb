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

require 'rubygems/package'
require 'seven_zip_ruby'
require 'zlib'
require 'zip'

module Armagh
  module Support
    module Extract

      class ExtractError < StandardError; end

      TYPE_EXTENSIONS = {
        'tar' => %w(.tar),
        'tgz' => %w(.tar.gz .tgz),
        'zip' => %w(.zip),
        '7zip' => %w(.7z)
      }

      TYPES = TYPE_EXTENSIONS.keys.sort

      ALLOWED_EXTENSIONS = TYPE_EXTENSIONS.values.flatten.uniq.sort

      def self.extract(string, filename: nil, type: nil, filename_pattern: nil)
        raise ExtractError, 'Either a filename or a type must be provided to determine which extractor to use.' if type.nil? && filename.nil?
        raise ExtractError, "Unknown type '#{type}'.  Expected one of: #{TYPES.join(', ')}." unless type.nil? || TYPES.include?(type)

        case
        when type?('tar', filename, type)
          extract_tar(string, filename_pattern: filename_pattern){|f, c| yield(f, c)}
        when type?('tgz', filename, type)
          extract_tgz(string, filename_pattern: filename_pattern){|f, c| yield(f, c)}
        when type?('zip', filename, type)
          extract_zip(string, filename_pattern: filename_pattern){|f, c| yield(f, c)}
        when type?('7zip', filename, type)
          extract_7zip(string, filename_pattern: filename_pattern){|f, c| yield(f, c)}
        else
          raise ExtractError, "File '#{filename}' needs to have one of the following extensions: #{ALLOWED_EXTENSIONS.join(', ')}."
        end
      end

      def self.extract_tar(string, filename_pattern: nil)
        io = StringIO.new(string)
        Gem::Package::TarReader.new(io) do |tar|
          tar.each do |entry|
            filename = entry.full_name
            yield(filename, entry.read) if entry.file? && match?(filename_pattern, filename)
          end
        end
      rescue
        raise ExtractError, 'Unable to untar.'
      end

      def self.extract_tgz(string, filename_pattern: nil)
        io = StringIO.new(string)
        Zlib::GzipReader.wrap(io) do |gz|
          Gem::Package::TarReader.new(gz) do |tar|
            tar.each do |entry|
              filename = entry.full_name
              yield(filename, entry.read) if entry.file? && match?(filename_pattern, filename)
            end
          end
        end
      rescue => e
        raise ExtractError, 'Unable to untgz.'
      end

      def self.extract_zip(string, filename_pattern: nil)
        io = StringIO.new(string.freeze)
        Zip::File.open_buffer(io) do |zip|
          zip.each do |entry|
            if entry.file?
              filename = entry.name
              yield(filename, entry.get_input_stream.read) if match?(filename_pattern, filename)
            end
          end
        end
      rescue
        raise ExtractError, 'Unable to unzip.'
      end

      def self.extract_7zip(string, filename_pattern: nil)
        io = StringIO.new(string)
        SevenZipRuby::Reader.open(io) do |szr|
          szr.entries.each do |entry|
            filename = entry.path
            yield(filename, szr.extract_data(entry)) if entry.file? && match?(filename_pattern, filename)
          end
        end
      rescue
        raise ExtractError, 'Unable to un7zip.'
      end

      private_class_method def self.match?(pattern, name)
        pattern.nil? || File.fnmatch?(pattern, name)
      end

      private_class_method def self.type?(expected_type, filename, provided_type)
        return expected_type == provided_type if provided_type

        TYPE_EXTENSIONS[expected_type].each do |extension|
          return true if filename.end_with? extension
        end
        false
      end
    end
  end
end
