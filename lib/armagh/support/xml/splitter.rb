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
require_relative '../../base/errors/armagh_error'

module Armagh
  module Support
    module XML
      module Splitter
        include Configh::Configurable

        define_parameter name: 'repeated_element_name',
                         group: 'xml_splitter',
                         description: 'Repeated element name used to split large XML into smaller XMLs',
                         type: 'string',
                         required: true,
                         prompt: 'Specify name for a repeated element <name>'

        class XMLSplitError            < ArmaghError;   notifies :ops; end
        class XMLTypeError             < XMLSplitError; end
        class XMLValueError            < XMLSplitError; end
        class RepElemNameValueNotFound < XMLSplitError; end

        module_function

        def split_parts(xml, config)
          raise Splitter::XMLTypeError, 'XML must be a string' unless xml.is_a?(String)
          raise Splitter::XMLValueError, 'XML cannot be nil or empty' if xml.nil? || xml.empty?
          small_xmls = []
          repeated_element_regex = %r/(?=<#{config.xml_splitter.repeated_element_name}(?:| .*?)>)/
          closing_repeated_element_regex = %r/(?=<\/#{config.xml_splitter.repeated_element_name}>)/
          xmls = xml.split(repeated_element_regex)

          if xmls.size > 1
            header = xmls.first
            footer = xmls.last.split("</#{config.xml_splitter.repeated_element_name}>").last.strip
            (1...xmls.size).each do |i|
              raise Splitter::RepElemNameValueNotFound, "Repeated element name must be present in XML split: #{xmls[i]}" unless xmls[i].match(repeated_element_regex) && xmls[i].match(closing_repeated_element_regex)
              xml = header + xmls[i] + (i == xmls.size-1 ? '' : footer)
              small_xmls.push(xml)
            end
          end

          small_xmls
        rescue XMLSplitError
          raise
        rescue => e
          raise XMLSplitError, e
        end
      end
    end
  end
end
