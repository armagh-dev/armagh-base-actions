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
#
require 'configh'

module Armagh
  module Support
    module XML
      module Divider
        class XMLDivideError       < StandardError;  end
        class MaxSizeTooSmallError < XMLDivideError; end

        def self.extended(base)
          base.include Configh::Configurable

          base.class_eval do
            define_parameter name: 'size_per_part',
                                   description: 'The size of parts that the source file is divided into (in bytes)',
                                   type: 'positive_integer',
                                   default: 1_000_000,
                                   required: false

            define_parameter name: 'xml_element',
                                   description: 'The name of the repeated node in the source XML file to be extracted',
                                   type: 'string',
                                   required: false
          end
        end


        def divided_parts(source, options)
          eof              = false
          @offset          = 0
          @size_per_part   = options.xml.size_per_part
          @xml_element     = options.xml.xml_element
          @processed_bytes = 0
          @total_bytes ||= IO.read(source).size

          while eof == false
            @sub_string      = IO.read(source, @size_per_part, @offset)
            @sub_string_size = @sub_string.size

            @header ||= divided_part_header
            @footer ||= IO.read(source).lines.last

            find_previous_complete_record if last_line_has_partial_record?

            errors = []
            errors << MaxSizeTooSmallError if (current_sub_string.size > @size_per_part)

            yield current_sub_string, errors if block_given?

            @processed_bytes += @sub_string.size
            @offset          += @sub_string.size

            eof = true if reached_last_part_from_file?
          end
        end

        def last_line
          @sub_string.lines.last
        end

        def reached_last_part_from_file?
          (@processed_bytes + @footer.size) >= @total_bytes
        end

        def current_sub_string
          if @offset == 0
            @sub_string + @footer
          else
            @header + @sub_string + @footer
          end
        end

        def find_previous_complete_record
          until (last_line_has_complete_record? && within_max_size?)
            @sub_string = drop_last_line_from_sub_string
          end
        end

        def last_line_has_partial_record?
          !last_line_has_closing_xml_element?
        end

        def last_line_has_complete_record?
          last_line_has_closing_xml_element? || @sub_string.lines.count == 1
        end

        def last_line_has_closing_xml_element?
          last_line[/\s*\/#{@xml_element}/] ? true : false
        end

        def within_max_size?
          current_sub_string.size <= @size_per_part
        end

        def divided_part_header
          header_lines = []
          complete_header = false

          @sub_string.lines.each do |line|
            if !line[/\s*#{@xml_element}/] && complete_header == false
              header_lines << line
            else
              complete_header = true
              next
            end
          end

          @header = header_lines.join
        end

        def drop_last_line_from_sub_string
          return @sub_string if @sub_string.lines.count == 1
          lines = @sub_string.lines
          lines.pop
          lines.join
        end

      end
    end
  end
end
