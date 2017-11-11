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
require_relative '../base/errors/armagh_error'

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
        description: 'If true, CDATA inner text will be ignored',
        type: 'boolean',
        default: true,
        required: true

      define_parameter name: 'force_breaks',
        description: 'If true, replaces all line breaks with HTML breaks',
        type: 'boolean',
        default: false,
        required: true

      define_parameter name: 'unescape_html',
        description: 'If true, unescapes all escaped HTML, e.g., &lt;tag&gt; becomes <tag> and will be interpreted as HTML by the browser.',
        type: 'boolean',
        default: false,
        required: true

      define_parameter name: 'preserve_hyperlinks',
        description: 'If true, preserves hyperlinks as working hyperlinks that always open in a new tab.',
        type: 'boolean',
        default: false,
        required: true

      class HTMLError        < ArmaghError; notifies :ops; end
      class InvalidHTMLError < HTMLError;   end
      class ExtractError     < HTMLError;   end

      HTML_TO_TEXT_SHELL = %W(#{`which w3m`.strip} -T text/html -cols 10000 -O UTF-8 -o alt_entity=false)
      HTML_PART_DELIMITER = '|~!@#^&*|'.freeze
      HTML_PAGE_DELIMITER = '*#Y*@^~YU'.freeze
      HTML_PAGE_BREAK = "\n\n--- PAGE %d ---\n\n".freeze
      HTML_ANCHOR_LABEL_LINK_REGEX = /<a(?:| .+?) href=["'](.+?)["'](?:| .+?)>(.+?)<\/a>/im

      def HTML.merge_multiple_pages(content_array)
        merged_content = ''

        content_array.each_with_index do |content, idx|
          merged_content << content
          merged_content << HTML_PAGE_BREAK % (idx + 2) unless idx == content_array.length - 1
        end
        merged_content
      end

      def html_to_text(*html_parts, config)
        num_parts = html_parts.length
        html_parts.map! do |part|
          raise InvalidHTMLError, "HTML must be a String, instead: #{part.class}" unless part.is_a?(String)
          part.dup
        end

        extract_pattern(html_parts.first, :after, config.html.extract_after.deep_copy)
        extract_pattern(html_parts.first, :until, config.html.extract_until.deep_copy)
        exclude_pattern(html_parts.first,         config.html.exclude.deep_copy)
        force_breaks(html_parts.first)         if config.html.force_breaks

        html_parts.each do |part|
          next if part.empty?
          extract_cdata(part, config.html.ignore_cdata)
          replace_apos_with_single_quote(part)
          strip_sup_tag(part)
        end
        html = html_parts.join(HTML_PART_DELIMITER)

        html = CGI::unescape_html(html) if config.html.unescape_html
        html = preserve_hyperlinks(html) if config.html.preserve_hyperlinks

        text = Shell.call_with_input(HTML_TO_TEXT_SHELL, html)
        text.include?(HTML_PART_DELIMITER) ? text.split(HTML_PART_DELIMITER, num_parts) : text
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

      private def preserve_hyperlinks(html)
        html.gsub!(HTML_ANCHOR_LABEL_LINK_REGEX) do |label_link|
          link = $1
          label = $2
          if !link.nil? && link[/^http/i] && !link[/#/] && link != label
            "#{label} [ #{link} ]"
          else
            label
          end
        end
        html
      end
    end
  end
end
