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
require_relative '../utils/json_divider'

module Armagh
  module Support
    module JSON
      module Divider
        include Configh::Configurable

        define_parameter name:        'source_encoding',
                         description: 'The encoding of the source file to be divided',
                         type:        'string',
                         default:     JSONDivider::DEFAULT_SOURCE_ENCODING.name.dup,
                                      ## JSONDivider::DEFAULT_SOURCE_ENCODING.name is frozen
                                      ## with encoding US-ASCII, which fails configh
                                      ## because it's frozen and not UTF-8,
                                      ## so we dup it to get an unfrozen copy
                         required:    false,
                         group:       'json_divider'

        define_parameter name:        'size_per_part',
                         description: 'The size of parts that the source file is divided into (in bytes)',
                         type:        'positive_integer',
                         default:     JSONDivider::DEFAULT_SIZE_PER_PART,
                         required:    false,
                         group:       'json_divider'

        define_parameter name:        'divide_target',
                         description: 'The JSON node that contains the array that needs to be divided and combined with the remaining JSON content',
                         type:        'string',
                         required:    true,
                         group:       'json_divider'

        def divided_parts(doc, config)
          divider = JSONDivider.new(doc.collected_file,
            'source_encoding' => config.json_divider.source_encoding,
            'size_per_part'   => config.json_divider.size_per_part,
            'divide_target'   => config.json_divider.divide_target
            )
          divider.divide do |part|
            yield part
          end
        end

      end
    end
  end
end
