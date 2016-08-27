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
    module Excel

      class ExcelError  < StandardError; end
      class NoTextError < ExcelError; end

      module_function

      EXCEL_TO_TEXT_SHELL = %w(ssconvert -T Gnumeric_html:html40frag <input_xls_file> <output_html_file>)

      def to_search_text(binary)
        process_excel(binary, :search)
      end

      def to_display_text(binary)
        process_excel(binary, :display)
      end

      def to_search_and_display_text(binary)
        process_excel(binary, :search, :display)
      end

      private_class_method def process_excel(binary, *modes)
        result   = {}
        uuid     = SecureRandom.uuid
        xls_file = uuid + '.xls'
        out_file = uuid + '.html'

        File.write(xls_file, binary)

        command    = EXCEL_TO_TEXT_SHELL.dup
        command[3] = xls_file
        command[4] = out_file

        Shell.call(command, ignore_error: ['WARNING', 'Unexpected element'],
                             catch_error: 'E Unsupported file format.')

        result = extract_text(out_file, modes)

        if result[modes.first].empty? || result[modes.last].empty?
          raise NoTextError, 'Unable to extract text from Excel document'
        end

        modes.size == 1 ? result[modes.first] : [result[modes.first], result[modes.last]]
      rescue Shell::MissingProgramError => e
        raise e
      rescue => e
        raise ExcelError, e
      ensure
        Dir.glob(uuid + '*').each { |file| File.delete(file) }
      end

      private_class_method def extract_text(out_file, modes)
        do_text = modes.include?(:search)
        do_html = modes.include?(:display)

        text  = '' if do_text
        html  = '' if do_html

        File.read(out_file).each_line do |line|
          line.strip!
          next if line == '<p><table border="1">'

          if line.start_with?('<caption>')
            sheet = line[/^<caption>(.*?)<\/caption>$/, 1].to_s.strip
            text << sheet << "\n" if do_text
            html << '<p><b>' << sheet << '</b></p><table>' if do_html
            next
          end

          if line == '<tr>'
            text << "\n" if do_text
            html << line if do_html
          end

          if line.start_with?('<td')
            value = line[/^<td.*?>(.*?)<\/td>$/m, 1].to_s.strip.gsub(/<.*?>/m, '')
            text << value << "\n" if do_text && !value.empty?
            if do_html
              td = line[/^(<td.*?>)/, 1].to_s.strip.gsub(/\s*style=".*?"\s*/m, '')
              html << td << value << '</td>' if do_html
            end
          end

          if line == '</tr>' && do_html
            html << line
          end

          if line == '</table>'
            text << "\n" if do_text
            html << '</table></p>' if do_html
          end
        end

        if do_text && do_html
          {search:  text.strip,
           display: html}
        elsif do_text
          {search:  text.strip}
        elsif do_html
          {display: html}
        end
      end

    end
  end
end
