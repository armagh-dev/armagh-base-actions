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

require_relative "../actions/divide"

module Armagh
  module Support
    module CSV
      extend Armagh::Actions::ParameterDefinitions

      module_function

      define_parameter name: 'size_per_part',
                             description: 'The size of parts that the source file is divided into (in bytes)',
                             type: Fixnum,
                             default: 1_000_000,
                             required: false

      define_parameter name: 'col_sep',
                             description: 'thee column separator for the source file',
                             type: String,
                             default: ',',
                             required: false

      define_parameter name: 'row_sep',
                             description: 'The row separator for the source file',
                             type: Symbol,
                             default: :auto,
                             required: false

      define_parameter name: 'quote_char',
                             description: 'The quote character for the source file',
                             type: String,
                             default: '"',
                             required: false

      def divided_parts(source:, size_per_part:, col_sep:, row_sep:, quote_char:)
        eof           = false
        offset        = 0

        while eof == false
          sub_string = IO.read(source, size_per_part, offset)
          sub_string_size = sub_string.size

          @headers      ||= sub_string.lines.first
          @header_count ||= @headers.scan(col_sep).count

          last_line       = sub_string.lines.last
          last_line_count = last_line.scan(col_sep).count

          if (last_line_count != @header_count) && (sub_string_size >= size_per_part)
            until last_line_count == @header_count
              sub_string = drop_last_line_from_sub_string(sub_string)

              last_line       = sub_string.lines.last
              last_line_count = last_line.scan(col_sep).count
            end
          end

          if offset == 0
            yield sub_string if block_given?
          else
            yield (@headers + sub_string) if block_given?
          end

          offset += sub_string.size
          eof    = true if (sub_string_size == sub_string.size) && (sub_string_size < size_per_part)
        end
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

      def combine_parts(parts)
        parts.inject("") do |complete_content, part|
          if complete_content.empty?
            complete_content << part
          else
            rows = part.split("\n")
            rows.shift
            part = rows.join("\n") + "\n"
            complete_content << part
          end
        end
      end

      def drop_last_line_from_sub_string(sub_string)
        return sub_string if sub_string.lines.count == 1
        lines = sub_string.lines
        lines.pop
        lines.join
      end
    end
  end
end
