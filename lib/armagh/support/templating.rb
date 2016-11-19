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
      class InvalidConfigError   < TemplatingError; end
      class UnusedAttributeError < TemplatingError; end

      def render_template(template_path, *mode, **context)
        process_modes(template_path, mode, context)
      end

      def render_partial(template_path, **context)
        process_template(template_path, context)
      end

      def template_config(setting = nil, mode = nil)
        @template_config ||= {
          pattern:                  '\{\{ \}\}',
          compact:                  true,
          trim:                     true,

          supported_modes:          [:text, :html],
          mode:                     nil,

          text_escape_html:         false,
          html_escape_html:         true,

          text_header:              '[[@title]]',
          html_header:              '<div class="[[@css]]">[[@title]]</div>',
          html_header_css:          'field_header',

          text_field:               '[[@label]][[@value]]',
          text_field_label:         '[[@label]]: ',
          html_field:               '<div class="[[@css]]">[[@label]][[@value]]</div>',
          html_field_label:         '<span>[[@label]]:</span>',
          html_field_css:           'field_value',

          text_field_empty:         '',
          html_field_empty:         '<div class="[[@css]]">[[@label]]</div>',
          html_field_empty_label:   '<span>[[@label]]:</span>',
          html_field_empty_css:     'field_empty',

          text_field_missing:       '',
          html_field_missing:       '<div class="[[@css]]">[[@label]]</div>',
          html_field_missing_label: '<span>[[@label]]:</span>',
          html_field_missing_css:   'field_empty',

          text_block_begin:         '',
          html_block_begin:         '<div class="[[@css]]">',
          html_block_begin_css:     'field_block',

          text_block_next:          '',
          html_block_next:          '</div><div class="[[@css]]">',
          html_block_next_css:      'field_block',

          text_block_end:           '',
          html_block_end:           '</div><br />'
        }

        case setting
        when nil
          @template_config
        when Hash
          setting.each do |key, value|
            key = mode ? :"#{mode}_#{key}" : :"#{key}"
            case key
            when :pattern
              raise InvalidConfigError, "Value for setting #{key.inspect} must be a non-empty string" unless value.is_a?(String) && !value.strip.empty?
            when :compact, :trim
              raise InvalidConfigError, "Value for setting #{key.inspect} must be a boolean" unless [true, false].include?(value)
            when :supported_modes
              error_msg = "Value for setting #{key.inspect} must be a non-empty array of symbols"
              raise InvalidConfigError, error_msg unless value.is_a?(Array) && !value.empty?
              value.each { |m| raise InvalidConfigError, error_msg unless m.is_a?(Symbol) }
            when :mode
              raise InvalidConfigError, "Unsupported #{key} #{value.inspect}, did you mean one of these? #{@template_config[:supported_modes]}" unless @template_config[:supported_modes].include?(value)
            end
            @template_config[key] = value
          end
        when Symbol, String
          setting = setting.to_sym if setting.is_a?(String)
          setting = :"#{mode}_#{setting}" if mode
          value = @template_config[setting]
          if value.nil?
            if setting == :mode
              raise InvalidModeError, "Templating mode not set, supported: #{@template_config[:supported_modes]}"
            else
              raise MissingConfigError, "Missing config setting #{setting.inspect}"
            end
          end
          value
        end
      end

      def mode?(check_mode)
        template_config(:mode) == check_mode
      end

      def header(title, **attributes)
        title = escape_html(title)
        attributes[:title] = title
        parse_attributes(attributes, :header)
      end

      def field(label = nil, value, **attributes)
        label   = escape_html(label)
        missing = value.nil?
        value   = escape_html(value.to_s.strip)
        setting =
          if missing
            :field_missing
          elsif value.empty?
            :field_empty
          else
            :field
          end
        attributes[:label] = label
        attributes[:value] = value
        parse_attributes(attributes, setting)
      end

      def block_begin(**attributes)
        parse_attributes(attributes, :block_begin)
      end

      def block_next(**attributes)
        parse_attributes(attributes, :block_next)
      end

      def block_from_int(i, **attributes)
        setting = i == 1 ? :block_begin : :block_next
        parse_attributes(attributes, setting)
      end

      def block_end(**attributes)
        parse_attributes(attributes, :block_end)
      end

      private def escape_html(value)
        return value if !template_config_from_mode(:escape_html) || value.nil? || value.empty?
        value = CGI.escape_html(value)
        value.gsub(/\n/, '<br />')
      end

      private def template_config_from_mode(setting)
        template_config(setting, template_config(:mode))
      end

      private def parse_attributes(attributes, setting)
        config_value = template_config_from_mode(setting)
        value        = config_value.dup
        mode         = template_config(:mode)
        attributes.each do |k, v|
          config_lookup = @template_config[:"#{mode}_#{setting}_#{k}"]
          v =
            if v.nil?
              ''
            elsif config_lookup && config_lookup.include?("[[@#{k}]]")
              config_lookup.sub(/\[\[@#{k}\]\]/, v.to_s)
            else
              v.to_s
            end
          value.sub!(/\[\[@#{k}\]\]/, v)
        end
        value.gsub!(/\[\[@(\w+)\]\]/) do
          check_config = @template_config[:"#{mode}_#{setting}_#{$1}"]
          raise UnusedAttributeError, "Unused [[@#{$1}]] attribute for config setting :#{mode}_#{setting} with value #{value.inspect}" unless check_config
          check_config
        end
        value
      end

      private def process_modes(template_path, mode, context)
        modes           = []
        user_modes      = Array(mode)
        supported_modes = template_config(:supported_modes)
        user_modes      = supported_modes if user_modes.empty?
        supported_modes.each do |m|
          modes << m if user_modes.include?(m)
        end
        if modes.empty?
          raise InvalidModeError, "Unknown mode(s) selected: #{user_modes - supported_modes}, supported: #{supported_modes}"
        end

        result = modes.size == 1 ? '' : []
        modes.each do |m|
          template_config(mode: m)
          result << process_template(template_path, context)
        end
        result
      end

      private def process_template(template_path, context)
        raise InvalidModeError, 'Did you try to render a partial template before mode(s) are set?' unless template_config(:mode)
        raise MissingTemplateError, 'Template file path cannot be blank' if template_path.to_s.strip.empty?
        raise MissingTemplateError, "Missing template file #{template_path.inspect}" unless File.exist?(template_path)

        context             = Erubis::Context.new(context)
        class_name          = convert_class_name_from_camel_to_snake
        context[class_name] = self
        methods_to_bind     = []

        self.class.ancestors.each_with_index do |klass, i|
          if i.zero?
            methods_to_bind  = klass.instance_methods
          else
            methods_to_bind -= klass.instance_methods
          end
        end

        methods_to_bind += self.private_methods(false)
        methods_to_bind += Templating.instance_methods

        methods_to_bind.each do |method|
          context.define_singleton_method(method) do |*args|
            context[class_name].send(method, *args)
          end
        end

        Erubis::FastEruby.new(
          File.read(template_path),
          pattern: template_config(:pattern),
          compact: template_config(:compact),
          trim:    template_config(:trim)
        ).evaluate(context).strip
      rescue LocalJumpError => e
        raise LocalJumpError, 'Binded methods that accept blocks and invoke yield are unsupported by Templating'
      rescue => e
        erubis_error = e.backtrace.first[/^.{0,1}erubis(:.*?)$/, 1]
        if erubis_error
          raise TemplateError, "#{e.message}\n#{File.basename(template_path)}#{erubis_error}"
        else
          raise e
        end
      end

      private def convert_class_name_from_camel_to_snake
        string = self.class.to_s.strip[/:?:?(\w+)$/, 1] || 'instance'
        return string.downcase if string[/^[A-Z]+$/]
        string.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end

    end
  end
end
