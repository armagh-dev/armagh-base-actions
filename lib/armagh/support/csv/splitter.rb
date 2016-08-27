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

require 'csv'

module Armagh
  module Support
    module CSV
      module Splitter

        class CSVError < StandardError; end
        class RowMissingValueError < CSVError; end
        class RowWithExtraValuesError < CSVError; end

        def split_parts(source, options)
          csv_string = source.content

          ::CSV.parse(csv_string, headers: true) do |row|
              errors = []
              errors << RowMissingValueError    if row.fields.include?(nil)
              errors << RowWithExtraValuesError if row.headers.include?(nil)
              yield row.to_hash, errors if block_given?
          end
        end

      end
    end
  end
end

