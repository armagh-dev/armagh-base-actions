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
require 'rubygems/package'
require_relative 'compress'

module Armagh
  module Support
    module Tar

      class TarError < StandardError; end

      TAR_PERMS = '0644'.freeze

      # Opens a new tar file and yields it.
      # @param file_path [String] Optional file path for tar.
      # @yieldparam tar The open tar file you can add to.
      #
      # @example Create tar file on disk
      #   Support::Tar.create_tar_file(file_path) do |tar|
      #     some_ary_of_docs_for_the_tar.each do |doc|
      #       tar.add <doc filename in the tar>, <doc content as a string>
      #     end
      #   end
      #
      # @example Create tar file as stringIO and return it
      #   tar_string_io = Support::Tar.create_tar_file(file_path) do |tar|
      #     some_ary_of_docs_for_the_tar.each do |doc|
      #       tar.add <doc filename in the tar>, <doc content as a string>
      #     end
      #   end
      #
      # @return [optional StringIO] tar as stringIO if no file_path was provided.
      def self.create_tar_file(file_path = nil)

        tar_str = ''
        tar = StringIO.new(tar_str)

        Gem::Package::TarWriter.new(tar) do |writer|

          def writer.add( filename, content )
            add_file( filename, TAR_PERMS ) do |f|
              f.write( content )
            end
          end

          yield writer

          writer.flush
        end
        tar.close

        file_path ? File.write(file_path, tar_str) : tar_str

      rescue => e
          raise TarError, "Unable to create tar file: #{ e.message }"
      end

      # Opens a new tgz file and yields it.
      # @param file_path [String] Optional file path for tgz.
      # @yieldparam tgz The open tgz file you can add to.
      # @see #create_tar_file
      def self.create_tgz_file( file_path=nil, &block )

        tar_str = create_tar_file( &block )
        tgz_str = Compress.compress(tar_str)

        file_path ? File.write( file_path, tgz_str ) : tgz_str
      end
    end
  end
end