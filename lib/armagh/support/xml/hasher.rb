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

require 'facets/kernel/deep_copy'

require 'ox'

module Armagh
  module Support
    module XML
      class Hasher < Ox::Sax
        def self.clean(value)
          value.to_s.strip
        end

        def initialize(xml = nil, html_nodes = nil)
          @stack       = []
          @html_values = {}
          if html_nodes.is_a? Array
            @html_nodes = html_nodes.deep_copy
          elsif html_nodes.nil?
            @html_nodes = []
          else
            @html_nodes = [html_nodes&.dup]
            @html_nodes.compact!
          end

          @html_nodes.each do |node|
            value = xml[/<#{node}>(.*)<\/#{node}>/m, 1]
            node = clean(node)
            @html_values[node] = clean(value)
          end
          @html_nodes.map! { |k, _| k = clean(k) }
        end

        private def clean(value)
          self.class.clean(value)
        end

        def start_element(name)
          name = clean(name)
          if @html_nodes.include? name
            @current_text_node = name
            @stack.push name => clean(@html_values[name])
          end
          @stack.push name => nil unless @current_text_node
        end

        def end_element(name)
          name = clean(name)
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
          current[key]["attr_#{clean(name)}"] = clean(value)
        end

        def text(value)
          return if @current_text_node
          current = @stack.last
          raise Armagh::Support::XML::Parser::XMLParseError, 'Attempting to apply text to an empty stack' unless current
          key = current.keys.first
          current[key] ||= {}
          if current[key].empty?
            current[key] = clean(value)
          else
            current[key]['text'] = clean(value)
          end
        end

        def cdata(value)
          text(clean(value))
        end

        def data
          @stack.first
        end
      end
    end
  end
end
