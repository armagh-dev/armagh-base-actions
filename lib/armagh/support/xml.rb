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

require 'ox'

module Armagh
  module Support
    module XML
      module_function

      class XMLParseError < StandardError; end

      def to_hash(xml, text_nodes = nil)
        io = StringIO.new(xml)
        file_to_hash(io, text_nodes)
      rescue => e
        raise XMLParseError, e
      ensure
        io.close if io
      end

      def file_to_hash(xml_file, text_nodes = nil)
        xml = xml_file.is_a?(StringIO) ? xml_file.read : File.read(xml_file)
        handler = Hasher.new(text_nodes, xml)
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

      class << self
        private def xml_node_to_hash(node)
          if node.text
            return [node.value, node.text]
          else
            result_hash = {}
            node.nodes.each do |child|
              result = xml_node_to_hash(child)
              node_name = clean_element(result.first)
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
                Hash[node.attributes.collect{ |k, v| ["attr_#{clean_element(k)}", v] }]
              result_hash.merge! mangled_attributes
            end
            [node.value, result_hash]
          end
        end
      end

      def clean_element(element)
        element.to_s.gsub(/\$|\./, '_')
      end

      class Hasher < Ox::Sax
        def initialize(text_nodes = nil, xml = nil)
          @stack       = []
          @text_values = {}
          @text_nodes  = Array(text_nodes)
          @text_nodes.each do |node|
            value = xml[/<#{node}>(.*)<\/#{node}>/m, 1]
            node = XML::clean_element(node)
            @text_values[node] = value
          end
          @text_nodes.map! { |k, _| k = XML::clean_element(k) }
        end

        def start_element(name)
          name = XML::clean_element(name)
          if @text_nodes.include? name
            @current_text_node = name
            @stack.push name => @text_values[name]
          end
          @stack.push name => nil unless @current_text_node
        end

        def end_element(name)
          name = XML::clean_element(name)
          @current_text_node = nil if @current_text_node == name
          return if @stack.size == 1 || @current_text_node
          element = @stack.pop
          current = @stack.last
          key = current.keys.first
          if current[key].nil? || !current[key].has_key?(name)
            current[key] ||= {}
            current[key].update(element)
          else
            current_key_name = current[key][name]
            current[key][name] = [current_key_name] unless current_key_name.is_a? Array
            current[key][name].push element[name]
          end
        end

        def attr(name, value)
          return if @stack.empty? || @current_text_node
          current = @stack.last
          key = current.keys.first
          current[key] ||= {}
          current[key]["attr_#{XML::clean_element(name)}"] = value
        end

        def text(value)
          return if @current_text_node
          current = @stack.last
          raise XMLParseError, 'Attempting to apply text to an empty stack' unless current
          key = current.keys.first
          current[key] ||= {}
          if current[key].empty?
            current[key] = value
          else
            current[key]['text'] = value
          end
        end

        def cdata(value)
          text(value)
        end

        def data
          @stack.first
        end
      end
    end
  end
end
