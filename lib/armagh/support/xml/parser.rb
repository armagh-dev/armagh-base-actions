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

require 'configh'
require_relative 'hasher'

module Armagh
  module Support
    module XML
      module Parser
        class XMLParseError < StandardError; end

        module_function

        def to_hash(xml, html_nodes = nil)
          io = StringIO.new(xml)
          file_to_hash(io, html_nodes)
        rescue => e
          raise XMLParseError, e
        ensure
          io.close if io
        end

        def file_to_hash(xml_file, html_nodes = nil)
          xml = xml_file.is_a?(StringIO) ? xml_file.read : File.read(xml_file)
          handler = XML::Hasher.new(xml, html_nodes)
          Ox.sax_parse(handler, xml)
          handler.data
        rescue => e
          raise XMLParseError, e
        ensure
          xml.close if xml.is_a?(StringIO)
        end

        def html_to_hash(html)
          html = html.prepend '<?xml?>' unless html[/<\?xml/]
          doc = Ox.load(html, effort: :tolerant)
          {doc.root.value.to_s => xml_node_to_hash(doc.root).last}
        rescue => e
          raise XMLParseError, e
        end

        private_class_method def self.xml_node_to_hash(node)
          if node.text
            return [node.value, node.text]
          else
            result_hash = {}
            node.nodes.each do |child|
              result = xml_node_to_hash(child)
              node_name = XML::Hasher.clean_element(result.first)
              if result_hash[node_name]
                if result_hash[node_name].is_a? Array
                  result_hash[node_name] << result.last
                else
                  result_hash[node_name] = [result_hash[node_name], result.last]
                end
              else
                result_hash[node_name] = result.last
              end
            end
            unless node.attributes.empty?
              mangled_attributes =
                Hash[node.attributes.collect{ |k, v| ["attr_#{XML::Hasher.clean_element(k)}", v] }]
              result_hash.merge! mangled_attributes
            end
            [node.value, result_hash]
          end
        end

      end
    end
  end
end
