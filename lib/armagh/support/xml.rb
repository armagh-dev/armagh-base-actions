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

require_relative '../base/actions'
Dir[File.join(__dir__, File.basename(__FILE__, ".*"), "*.rb")].each { |file| require file }

module Armagh
  module Support
    module XML
      include Configh::Configurable
      extend XML::Splitter
      extend XML::Divider
      extend XML::Parser

      define_parameter name: 'get_doc_id_from',
                       description: 'XML field/s that contain document ID',
                       type: 'string_array',
                       required: false,
                       group: 'xml'

      define_parameter name: 'get_doc_title_from',
                       description: 'XML field/s that contain document title',
                       type: 'string_array',
                       required: false,
                       group: 'xml'

      define_parameter name: 'get_doc_timestamp_from',
                       description: 'XML field/s that contain document timestamp',
                       type: 'string_array',
                       required: false,
                       group: 'xml'

      define_parameter name: 'timestamp_format',
                       description: 'Format for XML field/s that contain document timestamp',
                       type: 'string',
                       required: false,
                       group: 'xml'

      define_parameter name: 'get_doc_copyright_from',
                       description: 'XML field/s that contain document copyrights',
                       type: 'string_array',
                       required: false,
                       group: 'xml'

      define_parameter name: 'html_nodes',
                       description: 'HTML nodes that need to be kept as-is and not converted into a hash',
                       type: 'string_array',
                       required: false,
                       group: 'xml'

      module_function

      def to_hash(xml, html_nodes_no_parse = nil)
        Parser.to_hash(xml, html_nodes_no_parse)
      end

      def file_to_hash(xml, html_nodes_no_parse = nil)
        Parser.file_to_hash(xml, html_nodes_no_parse)
      end

      def html_to_hash(html)
        Parser.html_to_hash(html)
      end

      def dig_first(root, *nodes)
        return root if nodes.empty? || root.nil?

        root_array = root.is_a?(Array) ? root.dup : [root]
        nodes = nodes.dup

        next_node = nodes.shift
        root_array.each do |root_elem|
          sub = dig_first(root_elem[next_node], *nodes)
          return sub if sub
        end

        nil
      end

      def get_doc_attr(xml, attr_name)
        dig_first(xml, *attr_name)
      end
    end
  end
end
