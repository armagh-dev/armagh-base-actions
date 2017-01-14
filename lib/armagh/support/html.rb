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
require 'facets/kernel/deep_copy'

require_relative 'shell'

module Armagh
  module Support
    module HTML
      include Configh::Configurable

      define_parameter name: 'extract_after',
        description: 'Content will be extracted after this regex pattern (exclusive)',
        prompt: '<div class="article-text.*?>',
        type: 'string',
        required: false

      define_parameter name: 'extract_until',
        description: 'Content will be extracted until this regex pattern (exclusive)',
        prompt: '<div class="footer.*?>',
        type: 'string',
        required: false

      define_parameter name: 'exclude',
        description: 'Array of one or more regex patterns to exclude',
        prompt: '<div.*?</div>',
        type: 'string_array',
        required: false

      define_parameter name: 'ignore_cdata',
        description: 'If true, both CDATA tags and inner text will be ignored',
        type: 'boolean',
        default: true,
        required: true

      define_parameter name: 'force_breaks',
        description: 'If true, replaces all line breaks with HTML breaks',
        type: 'boolean',
        default: false,
        required: true

      class HTMLError        < StandardError; end
      class InvalidHTMLError < HTMLError; end
      class ExtractError     < HTMLError; end

      HTML_TO_TEXT_SHELL = %W(#{`which w3m`.strip} -T text/html -cols 10000 -O UTF-8 -o alt_entity=false)
      HTML_PART_DELIMITER = '|~!@#^&*|'

      def html_to_text(*html_parts, config)
        html_parts.map! do |part|
          raise InvalidHTMLError, "HTML must be a String, instead: #{part.class}" unless part.is_a?(String)
          raise InvalidHTMLError, 'HTML cannot be empty' if part.strip.empty?
          part.dup
        end

        extract_pattern(html_parts.first, :after, config.html.extract_after.deep_copy)
        extract_pattern(html_parts.first, :until, config.html.extract_until.deep_copy)
        exclude_pattern(html_parts.first,         config.html.exclude.deep_copy)
        force_breaks(html_parts.first)         if config.html.force_breaks

        html_parts.each do |part|
          extract_cdata(part, config.html.ignore_cdata)
          replace_apos_with_single_quote(part)
          strip_sup_tag(part)
        end

        html = html_parts.join(HTML_PART_DELIMITER)
        text = Shell.call_with_input(HTML_TO_TEXT_SHELL, html)
        text.include?(HTML_PART_DELIMITER) ? text.split(HTML_PART_DELIMITER) : text
      rescue HTMLError
        raise
      rescue => e
        raise HTMLError, e
      end

      private def extract_pattern(html, type, pattern)
        return unless pattern
        flexible_quotes(pattern)
        regex =
          case type
          when :after
            %r/^.*?#{pattern}/m
          when :until
            %r/#{pattern}.*$/m
          else
            raise ExtractError, "Invalid type argument specified #{type.inspect}"
          end
        validation = html.size
        html.sub!(regex, '')
        raise ExtractError, "Unable to match extract_#{type} '#{pattern}'" if validation == html.size
      end

      private def exclude_pattern(html, pattern_array)
        return unless pattern_array
        pattern_array.each do |pattern|
          flexible_quotes(pattern)
          html.gsub!(%r/#{pattern}/m, '')
        end
      end

      private def extract_cdata(html, ignore_cdata)
        if ignore_cdata
          html.gsub!(/<!\[CDATA\[.*?\]\]>/m, '')
        else
          html.gsub!(/\]\]\]><!\[CDATA\[\]>|\]\]\]\]><!\[CDATA\[>/, '')
          html.gsub!(/<!\[CDATA\[(.*?)\]\]>/m) { $1 }
        end
      end

      private def force_breaks(html)
        html.gsub!(/\n/, '<br \>')
      end

      private def replace_apos_with_single_quote(html)
        html.gsub!(/&apos;/, "'")
      end

      private def strip_sup_tag(html)
        html.gsub!(/<(?:\/|)sup(?: .*?|)>/i, '')
      end

      private def flexible_quotes(pattern)
        pattern.gsub!(/"|'/, '(?:"|\')')
      end

    end
  end
end
