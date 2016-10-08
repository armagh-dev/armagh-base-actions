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

require 'configh'

module Armagh
  module Support
    module CSV
      module Parser
        include Configh::Configurable

        class CSVParseError           < StandardError; end
        class RowMissingValueError    < CSVParseError; end
        class RowWithExtraValuesError < CSVParseError; end
        class BlockMissingError       < CSVParseError; end

        define_parameter name:        'col_sep',
                         description: 'The column separator for the source file',
                         type:        'string',
                         default:     ',',
                         required:    false,
                         group:       'csv_parser'

        define_parameter name:        'row_sep',
                         description: 'The row separator for the source file',
                         type:        'symbol',
                         default:     :auto,
                         required:    false,
                         group:       'csv_parser'

        define_parameter name:        'quote_char',
                         description: 'The quote character for the source file',
                         type:        'string',
                         default:     '"',
                         required:    false,
                         group:       'csv_parser'

        define_parameter name:        'headers',
                         description: 'Indicates whether or not headers are included in the source file',
                         type:        'boolean',
                         default:     true,
                         required:    false,
                         group:       'csv_parser'

        define_parameter name:        'non_standard_rows',
                         description: 'Specifies pattern for non-standard file padding rows that should be skipped (e.g. comments in the source file)',
                         type:        'string',
                         required:    false,
                         group:       'csv_parser'

        def each_line(doc, config)
          csv_content = doc.raw
          ::CSV.parse(csv_content, get_options(config)) do |row|
            errors = []
            errors << RowMissingValueError.new("A CSV row is missing one or more values") if row.fields.include?(nil)
            errors << RowWithExtraValuesError.new("A CSV row has one or more extra values") if row.headers.include?(nil)
            yield row.to_hash, errors
          end
        end

        private def get_options(config)
          {
            col_sep:            config.csv_parser.col_sep,
            row_sep:            config.csv_parser.row_sep,
            quote_char:         config.csv_parser.quote_char,
            return_headers:     false,
            headers:            config.csv_parser.headers,
            skip_lines:         config.csv_parser.non_standard_rows
          }
        end
      end
    end
  end
end
