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
require_relative 'doc_attr'
require_relative 'time_parser'

module Armagh
  module Support
    module FieldMap
      include Configh::Configurable
      include Armagh::Support::DocAttr
      include Armagh::Support::TimeParser

      define_parameter name: 'get_doc_id_from',
                       description: 'Field that contains document ID',
                       prompt:      'A field found by traversing the content, e.g. ["account_number"]',
                       type: 'string_array',
                       required: false,
                       group: 'field_map'

      define_parameter name: 'get_doc_title_from',
                       description: 'Field that contains document title',
                       prompt:      'A field found by traversing the content, e.g. ["filename"]',
                       type: 'string_array',
                       required: false,
                       group: 'field_map'

      define_parameter name: 'get_doc_copyright_from',
                       description: 'Field that contains document copyright',
                       prompt:      'A field found by traversing the content, e.g. ["copyright_notice"]',
                       type: 'string_array',
                       required: false,
                       group: 'field_map'

      define_parameter name: 'get_doc_timestamp_from',
                       description: 'Field that contains document timestamp',
                       prompt:      'A field found by traversing the content, e.g. ["saved_at"]',
                       type: 'string_array',
                       required: false,
                       group: 'field_map'


      def set_field_map_attrs(doc, config)
        return  if doc.nil?

        if config.respond_to?(:field_map)
          attr = get_field_map_attr(doc.content, field_map(config, :get_doc_id_from))
          doc.document_id = attr  unless attr.nil?

          attr = get_field_map_attr(doc.content, field_map(config, :get_doc_title_from))
          doc.title = attr  unless attr.nil?

          attr = get_field_map_attr(doc.content, field_map(config, :get_doc_copyright_from))
          doc.copyright = attr  unless attr.nil?

          attr = get_field_map_attr(doc.content, field_map(config, :get_doc_timestamp_from))
          doc.document_timestamp = (attr.is_a? Time) ? attr : parse_time(attr, config)  unless attr.nil?
        end

        doc.title              ||= doc.source.filename || "unknown"
        doc.document_timestamp ||= doc.source.mtime    || Time.now
        doc.copyright          ||= get_field_map_attr(doc.metadata, ['copyright'])  ## metadata may be an Array
      end

      def field_map(config, map_name)
        return nil  unless config.field_map.respond_to?(map_name)
        return config.field_map.send(map_name)
      end

      def get_field_map_attr(content, hpath)
        attr = get_doc_attr(content, hpath)

        ## the current field_map attrs are either a Time or a String (stripped)
        attr = attr.to_s.strip  unless attr.nil? || attr.is_a?(Time)

        return attr
      end


      def self.field_map_description
        <<~DESCDOC
        This action lets you define the elements, in group 'field_map', that will provide the
        document ID, title, timestamp, and copyright for the document being published.

        If an element you're after is nested, you can specify the path to the element part by part.
        For example, if the document ID should come from content['account']['number'], specify 'account'
        then 'number' in the interface.

        If an element comes from a known index in an Array, specify the index as a String.
        For example, if the timestamp should come from content['times'][2], specify 'times'
        then '2' in the interface.
        DESCDOC
      end

    end
  end
end
