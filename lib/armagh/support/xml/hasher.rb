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

require 'ox'

module Armagh
  module Support
    module XML
      class Hasher < Ox::Sax
        def self.clean_element(element)
          element.to_s.gsub(/\$|\./, '_')
        end

        def initialize(text_nodes = nil, xml = nil)
          @stack       = []
          @text_values = {}
          @text_nodes  = Array(text_nodes)
          @text_nodes.each do |node|
            value = xml[/<#{node}>(.*)<\/#{node}>/m, 1]
            node = clean_element(node)
            @text_values[node] = value
          end
          @text_nodes.map! { |k, _| k = clean_element(k) }
        end

        def clean_element(element)
          self.class.clean_element(element)
        end

        def start_element(name)
          name = clean_element(name)
          if @text_nodes.include? name
            @current_text_node = name
            @stack.push name => @text_values[name]
          end
          @stack.push name => nil unless @current_text_node
        end

        def end_element(name)
          name = clean_element(name)
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
          current[key]["attr_#{clean_element(name)}"] = value
        end

        def text(value)
          return if @current_text_node
          current = @stack.last
          raise Armagh::Support::XML::Parser::XMLParseError, 'Attempting to apply text to an empty stack' unless current
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