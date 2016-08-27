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

require 'securerandom'
require 'fileutils'

require_relative 'shell'
require_relative 'pdf'

module Armagh
  module Support
    module Word

      class WordError   < StandardError; end
      class NoTextError < WordError; end

      module_function

      WORD_TO_TEXT_SHELL = %w(soffice -env:UserInstallation=file:// --headless --invisible --norestore --quickstart --nologo --nolockcheck --convert-to pdf <input_word_file>)

      def to_search_text(binary)
        process_word(binary, :search)
      end

      def to_display_text(binary)
        process_word(binary, :display)
      end

      def to_search_and_display_text(binary)
        process_word(binary, :search, :display)
      end

      private_class_method def process_word(binary, *modes)
        result   = {}
        uuid     = SecureRandom.uuid
        work_dir = File.join(Dir.pwd, uuid)
        doc_file = uuid + '.doc'
        pdf_file = uuid + '.pdf'

        FileUtils.mkdir(work_dir)
        File.write(doc_file, binary)

        command     = WORD_TO_TEXT_SHELL.dup
        command[1] += work_dir
        command[10] = doc_file

        Shell.call(command)

        pdf_binary = File.read(pdf_file, mode: 'rb')
        modes.each do |mode|
          result[mode] =
            case mode
            when :search
              PDF.to_search_text(pdf_binary)
            when :display
              PDF.to_display_text(pdf_binary)
            end

          raise NoTextError, 'Unable to extract text from Word document' if result[mode].empty?
        end

        modes.size == 1 ? result[modes.first] : [result[modes.first], result[modes.last]]
      rescue Shell::MissingProgramError => e
        raise e
      rescue => e
        raise WordError, e
      ensure
        Dir.glob(work_dir + '*').each { |entry| FileUtils.rm_rf(entry) }
      end

    end
  end
end
