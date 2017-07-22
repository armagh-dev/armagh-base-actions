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

require 'securerandom'
require 'fileutils'

require_relative 'shell'
require_relative 'pdf'
require_relative '../base/errors/armagh_error'

module Armagh
  module Support
    module Word
      include PDF

      class WordError       < ArmaghError; notifies :ops; end
      class WordNoTextError < WordError;   end

      WORD_TO_TEXT_SHELL = %W(#{`which soffice`.strip} -env:UserInstallation=file:// --headless --invisible --norestore --quickstart --nologo --nolockcheck --convert-to pdf <input_word_file>)

      def word_to_text(binary)
        process_word(binary, :text)
      end

      def word_to_display(binary)
        process_word(binary, :display)
      end

      def word_to_text_and_display(binary)
        process_word(binary, :text, :display)
      end

      private def process_word(binary, *modes)
        result   = {}
        uuid     = SecureRandom.uuid
        work_dir = File.join(Dir.pwd, uuid)
        doc_file = uuid + '.doc'
        pdf_file = uuid + '.pdf'

        FileUtils.mkdir(work_dir)
        File.write(doc_file, binary, mode: 'wb')

        command     = WORD_TO_TEXT_SHELL.dup
        command[1] += work_dir
        command[10] = doc_file

        Shell.call(command)

        pdf_binary = File.read(pdf_file, mode: 'rb')

        modes.each do |mode|
          result[mode] =
            case mode
            when :text
              pdf_to_text(pdf_binary)
            when :display
              pdf_to_display(pdf_binary)
            end
        end

        modes.size == 1 ? result[modes.first] : [result[modes.first], result[modes.last]]
      rescue Shell::MissingProgramError, WordError
        raise
      rescue PDFNoTextError
        raise WordNoTextError, 'Unable to extract text from Word document'
      rescue => e
        raise WordError, e
      ensure
        Dir.glob(work_dir + '*').each { |entry| FileUtils.rm_rf(entry) }
      end

    end
  end
end
