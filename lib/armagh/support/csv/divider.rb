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
#

require 'configh'

module Armagh
  module Support
    module CSV
      module Divider
        include Configh::Configurable

        define_parameter name:        'size_per_part',
                         description: 'The size of parts that the source file is divided into (in bytes)',
                         type:        'positive_integer',
                         default:     1_000_000,
                         required:    false,
                         group:       'csv_divider'

        define_parameter name:        'col_sep',
                         description: 'the column separator for the source file',
                         type:        'string',
                         default:     ',',
                         required:    false,
                         group:       'csv_divider'

        define_parameter name:        'row_sep',
                         description: 'The row separator for the source file',
                         type:        'symbol',
                         default:     :auto,
                         required:    false,
                         group:       'csv_divider'

        define_parameter name:        'quote_char',
                         description: 'The quote character for the source file',
                         type:        'string',
                         default:     '"',
                         required:    false,
                         group:       'csv_divider'

        def divided_parts(source, config)
          eof            = false
          @offset        = 0
          @size_per_part = config.csv_divider.size_per_part
          @col_sep       = config.csv_divider.col_sep

          while eof == false
            @sub_string = IO.read(source, @size_per_part, @offset)
            @sub_string_size = @sub_string.size

            @headers      ||= divided_part_header
            @header_count ||= @headers.scan(@col_sep).count

            @last_line_count = last_line.scan(@col_sep).count

            find_previous_complete_record if last_line_has_partial_record?

            yield current_sub_string

            @offset += @sub_string.size
            eof    = true if reached_last_part_from_file?
          end
        end

        def last_line
          @sub_string.lines.last
        end

        def reached_last_part_from_file?
          last_line_not_dropped? && within_max_size?
        end

        def last_line_not_dropped?
          @sub_string_size == @sub_string.size
        end

        def current_sub_string
          if @offset == 0
            @sub_string
          else
            @headers + @sub_string
          end
        end

        def find_previous_complete_record
          until (last_line_has_complete_record? && within_max_size?)
            @sub_string = drop_last_line_from_sub_string
            @last_line_count = last_line.scan(@col_sep).count
          end
        end

        def last_line_has_partial_record?
          (@last_line_count != @header_count) && (@sub_string_size >= @size_per_part)
        end

        def last_line_has_complete_record?
          @last_line_count == @header_count
        end

        def within_max_size?
         @sub_string_size <= @size_per_part
        end

        def divided_part_header
          @headers = @sub_string.lines.first
        end

        def parts_sizes(parts)
          parts.each_with_object([]) do |part, ary|
            if ary.empty?
              ary << part.size
            else
              rows = part.split("\n")
              rows.shift
              part = rows.join
              ary << part.size
            end
          end
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

