# Copyright 2018 Noragh Analytics, Inc.
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
require_relative '../utils/csv_divider'

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

        def divided_parts(doc, config)
          divider = CSVDivider.new(doc.collected_file, size_per_part: config.csv_divider.size_per_part,
                                                       col_sep: config.csv_divider.col_sep)
          divider.divide do |part|
            yield part
          end
        end

      end
    end
  end
end
