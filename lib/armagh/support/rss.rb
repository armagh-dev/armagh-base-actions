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
require 'simple-rss'
require_relative 'http'

module Armagh
  module Support
    module RSS
      include Configh::Configurable
      include Armagh::Support::HTTP

      class RSSError < StandardError; end
      class RSSParseError < RSSError; end

      define_parameter name: 'max_items', description: 'Maximum number of items to collect', type: 'positive_integer', required: true, default: 100, prompt: '100'
      define_parameter name: 'content_field', description: 'Field containing content', type: 'symbol', required: false, prompt: 'field_name'
      define_parameter name: 'link_field', description: 'Field containing link to the content.', type: 'symbol', required: false, prompt: 'field_name', default: 'link'
      define_parameter name: 'additional_fields', description: 'Additional fields to collect from the RSS feed (in addition to the defaults', type: 'symbol_array', required: true, prompt: '[field1, field2]', default: []
      define_parameter name: 'full_collect', description: 'Do a collection of the full available RSS history.', type: 'boolean', required: true, default: false
      define_parameter name: 'description_no_content', description: 'Add the description as content in case there is no content.', type: 'boolean', required: true, default: false

      # TODO Validation (link or content field)

      # Additional media tags
      SimpleRSS.item_tags.concat [:'media:rating', :'media:rating#scheme', :'media:description', :'media:keywords',
                                  :'media:hash', :'media:hash#algo', :'media:copyright', :'media:copyright#url',
                                  :'media:text', :'media:license', :'media:license#type', :'media:license#href', :'link+alternate']
      SimpleRSS.item_tags.uniq!

      module_function

      def collect_rss(config)
        raise ArgumentError, 'Block must be provided to collect_rss, which yields |item, content_str, timestamp, exception|' unless block_given?
        setup_fields(config)

        http = HTTP::Connection.new(config)
        rss = fetch_rss(config, http)

        last_collect = config.rss.full_collect ? nil : Time.now # TODO Get the last timestamp instead of time.now.  Needs action state
        rss_items = get_filtered_rss(rss, last_collect, config.rss.max_items)


        content_field = config.rss.content_field
        link_field = config.rss.link_field

        rss_items.each do |item|
          error = nil
          begin
            content = content_field ? item[config.rss.content_field] : http.fetch(item[link_field])
            content = item[:description] if (content.nil? || content.empty?) && config.rss.description_no_content
          rescue RSSError => e
            error = e
          rescue => e
            error = RSSError.new("Unknown RSS error occurred from #{config.http.url}: #{e}.")
          end

          yield item, content, item[:armagh_timestamp], error
        end

      end

      private_class_method def setup_fields(config)
        config.rss.additional_fields.each {|f| SimpleRSS.item_tags << f}
        SimpleRSS.item_tags << config.rss.content_field if config.rss.content_field
        SimpleRSS.item_tags << config.rss.content_field if config.rss.link_field
        SimpleRSS.item_tags.uniq!
      end

      private_class_method def fetch_rss(config, http)
        http_response = http.fetch

        rss = nil
        begin
          rss = SimpleRSS.parse(http_response['body'])
        rescue => e
          raise RSSParseError, "Unable to parse RSS content from #{config.http.url}.  #{e}."
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
