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
      module_function

      class WordError   < StandardError; end
      class NoTextError < WordError; end

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
        doc_file = uuid + '.doc'
        work_dir = File.join(Dir.pwd, uuid)
        pdf_file = File.basename(doc_file, '.*') + '.pdf'

        FileUtils.mkdir(work_dir)
        File.open(doc_file, 'wb') { |f| f << binary }

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

          sanitize_bullet_points(result[mode])

          raise NoTextError, 'Unable to extract text from Word document' if result[mode].empty?
        end

        modes.size == 1 ? result[modes.first] : [result[modes.first], result[modes.last]]
      rescue => e
        raise WordError, e
      ensure
        Dir.glob(work_dir + '*').each { |entry| FileUtils.rm_rf(entry) }
      end

      private_class_method def sanitize_bullet_points(text)
        # TODO move this windows bullet special character cleanup to a common place
        text.gsub!(/\uf0b7|\uf0a7|\uf076|\uf0d8|\uf0fc|\uf0a8|\uf0de|\uf0e0/, "\u2022")
        text.gsub!(/[\ue800-\uf799]/, ' ')
      end

    end
  end
end
