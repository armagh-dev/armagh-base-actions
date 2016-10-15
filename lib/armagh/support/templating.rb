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

require 'erubis'
require 'cgi'

module Armagh
  module Support
    module Templating

      class TemplatingError      < StandardError; end
      class TemplateError        < TemplatingError; end
      class MissingTemplateError < TemplatingError; end
      class InvalidModeError     < TemplatingError; end
      class MissingConfigError   < TemplatingError; end

      module_function

      def render_template(template_path, *mode, bind: binding())
        mode = template_config(:supported_modes) if mode.empty?
        process_modes(template_path, mode, bind)
      end

      def render_partial(template_path)
        process_template(template_path, binding())
      end

      def template_config(setting = nil, mode = nil)
        @template_config ||= {
          pattern:            '\{\{ \}\}',
          compact:            true,
          trim:               true,

          supported_modes:    [:text, :html],

          text_escape_html:   false,
          html_escape_html:   true,

          text_header:        '@title',
          html_header:        '<div class="field_header">@title</div>',

          text_field:         '@label: @value',
          html_field:         '<div><span>@label:</span>@value</div>',

          text_field_empty:   '',
          html_field_empty:   '<div class="field_empty"><span>@label:</span></div>',

          text_field_missing: '',
          html_field_missing: '<div class="field_empty"><span>@label:</span></div>',

          text_block_begin:   '',
          html_block_begin:   '<div class="field_block">',

          text_block_next:    '',
          html_block_next:    '</div><div class="field_block">',

          text_block_end:     '',
          html_block_end:     '</div><br />'
        }

        case setting
        when nil
          @template_config
        when Hash
          setting.map! { |k, _v| k = :"#{mode}_#{k}" } if mode && setting
          @template_config.merge! setting
        when Symbol, String
          setting = setting.to_sym unless setting.is_a?(Symbol)
          setting = :"#{mode}_#{setting}" if mode && setting
          value = @template_config[setting]
          if value.nil?
            if setting == :mode
              raise MissingConfigError, "Templating mode not set, supported: #{@template_config[:supported_modes]}"
            else
              raise MissingConfigError, "Missing config setting #{setting.inspect}"
            end
          end
          value
        end
      end

      def mode
        template_config(:mode)
      end

      def header(title, mode = template_config(:mode))
        title = CGI::escapeHTML(title) if template_config(:escape_html, mode)
        template_config(:header, mode).sub(/@title/, title)
      end

      def field(label, value, mode = template_config(:mode))
        missing = value.nil?
        value   = value.to_s.strip
        if template_config(:escape_html, mode)
          label = CGI::escapeHTML(label)
          value = CGI::escapeHTML(value)
        end
        key =
          if missing
            :field_missing
          elsif value.empty?
            :field_empty
          else
            :field
          end
        template_config(key, mode).sub(/@label/, label).sub(/@value/, value)
      end

      def block_begin(mode = template_config(:mode))
        template_config(:block_begin, mode)
      end

      def block_next(mode = template_config(:mode))
        template_config(:block_next, mode)
      end

      def block_from_int(i, mode = template_config(:mode))
        template_config(i == 1 ? :block_begin : :block_next, mode)
      end

      def block_end(mode = template_config(:mode))
        template_config(:block_end, mode)
      end

      private_class_method def process_modes(template_path, mode, bind)
        modes = []
        user_modes = Array(mode)
        supported_modes = template_config(:supported_modes)
        supported_modes.each do |m|
          modes << m if user_modes.include?(m)
        end
        if modes.empty?
          raise InvalidModeError, "Unknown mode(s) selected: #{user_modes - supported_modes}, supported: #{supported_modes}"
        end

        result = modes.size == 1 ? '' : []
        modes.each do |m|
          template_config(mode: m)
          result << process_template(template_path, bind)
        end
        result
      end

      private_class_method def process_template(template_path, bind)
        raise InvalidModeError, 'Did you try to render a partial template before mode(s) are set?' unless template_config(:mode)
        raise MissingTemplateError, 'Template file path cannot be blank' if template_path.to_s.strip.empty?
        raise MissingTemplateError, "Missing template file #{template_path.inspect}" unless File.exist?(template_path)
        Erubis::FastEruby.new(
          File.read(template_path),
          pattern: template_config(:pattern),
          compact: template_config(:compact),
          trim:    template_config(:trim)
        ).result(bind).strip

      rescue => e
        erubis_error = e.backtrace.first[/^.{0,1}erubis(:.*?)$/, 1]
        if erubis_error
          raise TemplateError, "#{e.message}\n#{File.basename(template_path)}#{erubis_error}"
        else
          raise e
        end
      end

    end
  end
end
