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

require 'cgi'
require 'configh'
require 'simple-rss'
require 'facets/hash/stringify_keys'
require_relative 'http'

module Armagh
  module Support
    module RSS
      include Configh::Configurable
      include Armagh::Support::HTTP

      class RSSError < StandardError; end
      class RSSParseError < RSSError; end

      define_parameter name: 'max_items', description: 'Maximum number of items to collect', type: 'positive_integer', required: true, default: 100, prompt: '100'
      define_parameter name: 'link_field', description: 'Field containing link to the content.', type: 'string', prompt: 'field_name', default: 'link'
      define_parameter name: 'content_field', description: 'Field containing content.', type: 'string', required: false, prompt: 'field_name'
      define_parameter name: 'collect_link', description: 'Collect data from the content link, not the content field.', type: 'boolean', required: true, default: false
      define_parameter name: 'additional_fields', description: 'Additional fields to collect from the RSS feed (in addition to the defaults', type: 'string_array', required: true, prompt: '[field1, field2]', default: []
      define_parameter name: 'full_collect', description: 'Do a collection of the full available RSS history.', type: 'boolean', required: true, default: false
      define_parameter name: 'description_no_content', description: 'Add the description as content in case there is no content.', type: 'boolean', required: true, default: false
      define_parameter name: 'passthrough', description: "Don't try to populate fields during the collect phase.", type: 'boolean', required: true, default: false, group: 'rss'

      # Additional media tags
      SimpleRSS.item_tags.concat [:'media:rating', :'media:rating#scheme', :'media:description', :'media:keywords',
                                  :'media:hash', :'media:hash#algo', :'media:copyright', :'media:copyright#url',
                                  :'media:text', :'media:license', :'media:license#type', :'media:license#href', :'link+alternate']
      SimpleRSS.item_tags.uniq!

      module_function

      def collect_rss(config, state)
        raise ArgumentError, 'Block must be provided to collect_rss, which yields |item, content_array, type, timestamp, exception|' unless block_given?
        setup_fields(config)

        http = HTTP::Connection.new(config)
        http_response = http.fetch.first
        rss = parse_response(config, http_response)

        parent_type = HTTP.extract_type(http_response['head'])

        last_collect = config.rss.full_collect ? nil : state.content['last_collect']
        rss_items = get_filtered_rss(rss, last_collect, config.rss.max_items)

        content_field = config.rss.content_field
        content_field = clean_field(content_field).to_sym if content_field

        link_field = config.rss.link_field
        link_field = clean_field(link_field).to_sym

        channel = {}
        SimpleRSS.feed_tags.each{|t| channel[t.to_s] = rss.send(t) if rss.respond_to?(t)}

        rss_items.each do |item|
          content = []
          error = nil
          begin
            if config.rss.collect_link
              response = http.fetch(item[link_field])

              response.each do |item|
                content << item['body']
              end

              if item[:media_content_type]
                type = {'type' => item[:media_content_type], 'encoding' => 'binary'}
              else
                type = HTTP.extract_type(response.first['head']) || parent_type
              end
            else
              if content_field
                type = parent_type
                content_text = CGI.unescape_html(item[content_field]) # TODO JBOWES
                content << content_text
              else
                type = parent_type
              end
            end
          rescue => e
            error = RSSError.new("Unknown RSS error occurred from #{config.http.url}: #{e}.")
          end

          content.compact!

          content = [item[:description]] if (content.empty?) && config.rss.description_no_content
          timestamp = item[:armagh_timestamp]
          item.stringify_keys!

          yield channel, item, content, type, timestamp, error

          state.content['last_collect'] = timestamp if state.content['last_collect'].nil? || timestamp > state.content['last_collect']
        end

      end

      private_class_method def clean_field(field)
        cleaned = field.gsub(':', '_')
        cleaned.gsub!('#', '_')
        cleaned.gsub!(' ', '_')
        cleaned
      end

      private_class_method def setup_fields(config)
        config.rss.additional_fields.each {|f| SimpleRSS.item_tags << f}
        SimpleRSS.item_tags << config.rss.content_field.to_sym if config.rss.content_field
        SimpleRSS.item_tags << config.rss.link_field.to_sym
        SimpleRSS.item_tags.uniq!
      end

      private_class_method def parse_response(config, http_response)
        rss = nil
        begin
          rss = SimpleRSS.parse(http_response['body'])
        rescue => e
          raise RSSParseError, "Unable to parse RSS content from #{config.http.url}.  #{e}. Response body: #{ http_response[ 'body' ]}"
        end
        rss
      end

      private_class_method def get_filtered_rss(rss, ignore_before_ts, max_items)
        filtered = rss.items.delete_if do |item|
          item_timestamp = item[:updated] || item[:modified] || item[:pubDate] || item[:published] || item[:'dc:date'] || Time.now
          item[:armagh_timestamp] = item_timestamp
          ignore_before_ts && item_timestamp <= ignore_before_ts
        end

        filtered.sort! {|a,b| a[:armagh_timestamp] <=> b[:armagh_timestamp]}
        filtered = filtered.first(max_items) if max_items
        filtered
      end
    end
  end
end
