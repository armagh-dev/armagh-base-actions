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

require_relative 'shell'
require_relative '../base/errors/armagh_error'

module Armagh
  module Support
    module PDF

      class PDFError        < ArmaghError; notifies :ops; end
      class PDFTimeoutError < PDFError;    end
      class PDFNoTextError  < PDFError;    end

      DEFAULT_TIMEOUT     = 600
      PDF_TO_TEXT_SHELL   = %W(#{`which pdftotext`.strip} <input_pdf_file> -)
      PDF_TO_IMAGE_SHELL  = %W(#{`which gs`.strip} -dSAFER -sDEVICE=png16m -dINTERPOLATE -dNumRenderingThreads=8 -dFirstPage= -dLastPage= -r300 -o <output_image_file> -c 30000000 setvmthreshold -f <input_pdf_file>)
      IMAGE_TO_TEXT_SHELL = %W(#{`which tesseract`.strip} <input_image_file> <output_text_file> -psm 1)

      def pdf_to_text(binary, timeout: nil)
        process_pdf(binary, :text, timeout: timeout)
      end

      def pdf_to_display(binary, timeout: nil)
        process_pdf(binary, :display, timeout: timeout)
      end

      def pdf_to_text_and_display(binary, timeout: nil)
        process_pdf(binary, :text, :display, timeout: timeout)
      end

      private def process_pdf(binary, *modes, timeout:)
        result   = {}
        pdf_file = SecureRandom.uuid + '.pdf'

        File.write(pdf_file, binary, mode: 'wb')

        Timeout.timeout(timeout || DEFAULT_TIMEOUT) do
          modes.each do |mode|
            command    = PDF_TO_TEXT_SHELL.dup
            command[1] = pdf_file
            command.insert(1, '-layout') if mode == :display

            result[mode] = Shell.call(command)

            result[mode] = optical_character_recognition(pdf_file) if result[mode].empty?
            raise PDFNoTextError, 'Unable to extract PDF text content' if result[mode].empty?
            sanitize_bullet_points(result[mode])
          end
        end

        modes.size == 1 ? result[modes.first] : [result[modes.first], result[modes.last]]
      rescue Shell::MissingProgramError, PDFError
        raise
      rescue Timeout::Error, PDFTimeoutError
        raise PDFTimeoutError, 'Execution expired while processing PDF document'
      rescue => e
        raise PDFError, e
      ensure
        Dir.glob(pdf_file + '*').each { |file| File.delete(file) }
      end

      private def optical_character_recognition(pdf_file)
        result     = ''
        image_file = pdf_file + '.png'

        1.upto(Float::INFINITY) do |page|
          command     = PDF_TO_IMAGE_SHELL.dup
          command[5] += page.to_s
          command[6] += page.to_s
          command[9]  = image_file
          command[14] = pdf_file

          text = Shell.call(command)

          if text.include?("Processing pages #{page} through #{page}.")
            command    = IMAGE_TO_TEXT_SHELL.dup
            command[1] = image_file
            command[2] = pdf_file

            Shell.call(command, ignore_error: 'Tesseract Open Source OCR Engine')

            text = File.read(pdf_file + '.txt').strip
          else
            break
          end

          result << text + "\n" unless text.empty?
        end

        result.strip
      end

      private def sanitize_bullet_points(content)
        content.gsub!(/\uf0b7|\uf0a7|\uf076|\uf0d8|\uf0fc|\uf0a8|\uf0de|\uf0e0/, "\u2022")
        content.gsub!(/[\ue800-\uf799]/, ' ')
      end

    end
  end
end
