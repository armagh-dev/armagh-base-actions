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

require_relative 'shell'

module Armagh
  module Support
    module PDF
      module_function

      class PDFError     < StandardError; end
      class TimeoutError < PDFError; end
      class NoTextError  < PDFError; end

      DEFAULT_TIMEOUT     = 600
      PDF_TO_TEXT_SHELL   = %w(pdftotext <pdf_file> -)
      PDF_TO_IMAGE_SHELL  = %w(gs -dSAFER -sDEVICE=png16m -dINTERPOLATE -dNumRenderingThreads=8 -dFirstPage= -dLastPage= -r300 -o <output_image_file> -c 30000000 setvmthreshold -f <input_pdf_file>)
      IMAGE_TO_TEXT_SHELL = %w(tesseract <input_image_file> <output_pdf_file> -psm 1)

      def to_search_text(binary, timeout: DEFAULT_TIMEOUT)
        process_pdf(binary, :search, timeout: timeout)
      end

      def to_display_text(binary, timeout: DEFAULT_TIMEOUT)
        process_pdf(binary, :display, timeout: timeout)
      end

      def to_search_and_display_text(binary, timeout: DEFAULT_TIMEOUT)
        process_pdf(binary, :search, :display, timeout: timeout)
      end

      private_class_method def process_pdf(binary, *modes, timeout: DEFAULT_TIMEOUT)
        result   = {}
        pdf_file = SecureRandom.uuid + '.pdf'
        File.open(pdf_file, 'wb') { |file| file << binary }

        Timeout.timeout(timeout) do
          modes.each do |mode|
            command    = PDF_TO_TEXT_SHELL.dup
            command[1] = pdf_file
            command.insert(1, '-layout') if mode == :display

            result[mode] = Shell.call(command, timeout: timeout)

            result[mode] = optical_character_recognition(pdf_file) if result[mode].empty?

            raise NoTextError, 'Unable to extract PDF text content' if result[mode].empty?
          end
        end

        modes.size == 1 ? result[modes.first] : [result[modes.first], result[modes.last]]
      rescue Timeout::Error, TimeoutError
        raise TimeoutError, 'Execution expired while processing PDF'
      rescue NoTextError => e
        raise NoTextError, e
      rescue => e
        raise PDFError, e
      ensure
        Dir.glob(pdf_file + '*').each { |entry| FileUtils.rm_rf(entry) }
      end

      private_class_method def optical_character_recognition(pdf_file)
        result = ''

        1.upto(Float::INFINITY) do |page|
          image_file = pdf_file + '.png'
          begin
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

            result << text + "\n" unless text.strip.empty?
          end
        end

        result.strip
      end

    end
  end
end
