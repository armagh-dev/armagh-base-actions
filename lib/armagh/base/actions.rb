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

require_relative 'actions/version'

require 'fileutils'

module Armagh
  module Base
    module Actions
      BASE_ASSET_PATH = File.join(__dir__, '..', '..', '..', 'assets')
      ASSET_FILES = Dir.glob(File.join(BASE_ASSET_PATH, '**', '*'))
      NAME_FLAG = '[NAME]'
      FILENAME_FLAG = '[FILE_NAME]'

      def self.create_scaffolding(name)
        filename = create_filename(name) << '-client_actions'
        FileUtils.mkdir_p filename
        create_scaffold_files(name, filename)
      end

      def self.create_filename(name)
        filename = name.downcase
        filename.gsub!(/\s+/, '_')
        filename
      end

      private
      def self.create_scaffold_files(name, filename)
        ASSET_FILES.each do |asset_file|
          dest = File.join(filename, asset_file.sub(BASE_ASSET_PATH, '').gsub(FILENAME_FLAG, filename))

          if File.file? asset_file
            FileUtils.mkdir_p File.dirname(dest)
            text = File.read(asset_file)
            text.gsub!(NAME_FLAG, name)
            text.gsub!(FILENAME_FLAG, filename)
            File.open(dest, 'w') { |file| file.puts text }
          end
        end
      end
    end
  end
end
