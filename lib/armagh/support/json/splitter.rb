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

require 'configh'
require_relative '../../base/errors/armagh_error'

module Armagh
  module Support
    module JSON
      module Splitter
        include Configh::Configurable

        define_parameter name:        'split_target',
                         description: 'The JSON node that contains the array that needs to be divided and combined with the remaining JSON content',
                         type:        'string',
                         required:    true,
                         group:       'json_splitter'

        class JSONSplitError < ArmaghError;   notifies :ops; end
        class JSONTypeError  < JSONSplitError; end
        class JSONValueError < JSONSplitError; end
        class JSONParseError < JSONSplitError; end

        module_function

        def split_parts(json_string, config)
          raise Splitter::JSONTypeError, 'JSON must be a string' unless json_string.is_a?(String)
          raise Splitter::JSONValueError, 'JSON cannot be nil or empty' if json_string.nil? || json_string.empty?
          small_jsons = []

          begin
            json = ::JSON.parse(json_string)
          rescue ::JSON::ParserError
            raise JSONParseError, "Unable to parse JSON string passed to JSONSplitter library: #{$!.message}"
          end

          elements_to_divide = json[config.json_splitter.split_target]
          json_shell = json.dup
          json_shell.delete(config.json_splitter.split_target)

          elements_to_divide.each do |element|
            divided_part = json_shell.dup
            divided_part[config.json_splitter.split_target] = []
            divided_part[config.json_splitter.split_target] << element
            small_jsons << divided_part.to_json
          end

          small_jsons
        end
      end
    end
  end
end
