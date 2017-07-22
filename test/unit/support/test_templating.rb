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


require_relative '../../helpers/coverage_helper'

require 'test/unit'
require 'fakefs/safe'

require_relative '../../../lib/armagh/support/templating'

class TestTemplating < Test::Unit::TestCase
  include Armagh::Support::Templating

  private def set_mode_text; @template_config[:mode] = :text end
  private def set_mode_html; @template_config[:mode] = :html end

  private def custom_private_helper(arg)
    "custom_private_helper: #{arg}"
  end

  def custom_public_helper(arg)
    "custom_public_helper: #{arg}"
  end

  def custom_helper_with_unsupported_yield(arg)
    yield
  end

  def setup
    @template = 'template.erubis'
    @partial_template = 'partial_template.erubis'

    template = <<-end.gsub(/^\s+\| /, '')
      | {{= header 'Title' }}
      | {{- block_begin }}
      | {{= field 'Label', 'Value' }}
      | {{- block_next }}
      | {{= render_partial '#{@partial_template}' }}
      | {{- block_end }}
    end
    FakeFS { File.write(@template, template) }

    partial_template = <<-end.gsub(/^\s+\| /, '')
      | {{= header 'Partial' }}
      | {{= field 'Empty', '' }}
      | {{= field 'Missing', nil }}
    end
    FakeFS { File.write(@partial_template, partial_template) }

    @expected_text  = "Title\nLabel: Value\nPartial"
    @expected_html  = "<div class=\"field_header\">Title</div>\n<div class=\"field_value\"><span>Label: </span>Value</div>\n<div class=\"field_header\">Partial</div>\n<div class=\"field_empty\"><span>Empty:</span></div>\n<div class=\"field_empty\"><span>Missing:</span></div>"
    @expected_array = [@expected_text, @expected_html]
    template_config # initialize default config
  end

  #
  # render_template
  #

  def test_render_template_text
    assert_equal @expected_text, FakeFS { render_template(@template, :text) }
  end

  def test_render_template_html
    assert_equal @expected_html, FakeFS { render_template(@template, :html) }
  end

  def test_render_template_text_and_html
    assert_equal @expected_array, FakeFS { render_template(@template, :text, :html) }
  end

  def test_render_template_html_and_text
    assert_equal @expected_array, FakeFS { render_template(@template, :html, :text) }
  end

  def test_render_template_default_mode
    assert_equal @expected_array, FakeFS { render_template(@template) }
  end

  def test_render_template_unknown_mode
    e = assert_raise InvalidModeError do
      render_template(@template, :unknown)
    end
    assert_equal 'Unknown mode(s) selected: [:unknown], supported: [:text, :html]', e.message
  end

  def test_render_template_nil_template
    e = assert_raise MissingTemplateError do
      render_template(nil, :text)
    end
    assert_equal 'Template file path cannot be blank', e.message
  end

  def test_render_template_argument_error
    FakeFS { File.write(@template, '{{= header }}') }
    e = assert_raise ArgumentError do
      FakeFS { render_template(@template, :text) }
    end
    assert_equal 'wrong number of arguments (given 0, expected 1)', e.message
  end

  def test_render_template_calling_custom_private_template_helper_method
    FakeFS { File.write(@template, '{{= custom_private_helper(self.class) }}') }
    assert_equal 'custom_private_helper: Erubis::Context', FakeFS { render_template(@template, :text) }
  end

  def test_render_template_calling_custom_public_template_helper_method
    FakeFS { File.write(@template, '{{= custom_public_helper(self.class) }}') }
    assert_equal 'custom_public_helper: Erubis::Context', FakeFS { render_template(@template, :text) }
  end

  def test_render_template_calling_custom_public_template_helper_method_via_instance_variable
    FakeFS { File.write(@template, '{{= @test_templating.custom_public_helper(self.class) }}') }
    assert_equal 'custom_public_helper: Erubis::Context', FakeFS { render_template(@template, :text) }
  end

  def test_render_template_calling_custom_template_helper_with_unsupported_yield
    FakeFS { File.write(@template, '{{= custom_helper_with_unsupported_yield(self.class) { "content" } }}') }
    e = assert_raise LocalJumpError do
      FakeFS { render_template(@template, :text) }
    end
    assert_equal 'Binded methods that accept blocks and invoke yield are unsupported by Templating', e.message
  end

  #
  # render_partial
  #

  def test_render_partial_with_context
    FakeFS { File.write('partial.erubis', "{{= field 'Letter', @letter }}") }
    FakeFS { File.write(@template, '{{= @letter }}-{{= render_partial "partial.erubis", letter: @letter }}') }
    ['a', 'b', 'c'].each do |letter|
      assert_equal "#{letter}-Letter: #{letter}", FakeFS { render_template(@template, :text, letter: letter) }
    end
  end

  def test_render_partial_calling_custom_template_helper_method
    FakeFS { File.write('partial.erubis', "{{= custom_public_helper(self.class) }}") }
    FakeFS { File.write(@template, '{{= render_partial "partial.erubis" }}') }
    assert_equal 'custom_public_helper: Erubis::Context', FakeFS { render_template(@template, :text) }
  end

  def test_render_partial_nested
    FakeFS { File.write('1.erubis', "Partial 1: {{= render_partial '2.erubis' }}") }
    FakeFS { File.write('2.erubis', "Partial 2: {{= render_partial '3.erubis' }}") }
    FakeFS { File.write('3.erubis', 'Partial 3: Success!') }
    FakeFS { File.write(@template, "Master: {{= render_partial '1.erubis' }}") }
    assert_equal 'Master: Partial 1: Partial 2: Partial 3: Success!', FakeFS { render_template(@template, :text) }
  end

  #
  # template_config
  #

  def test_template_config_get
    assert_equal '[[@title]]', template_config(:text_header)
  end

  def test_template_config_get_by_mode
    assert_equal '[[@title]]', template_config(:header, :text)
  end

  def test_template_config_get_by_string
    assert_equal '[[@title]]', template_config('text_header')
  end

  def test_template_config_get_by_string_and_mode
    assert_equal '[[@title]]', template_config('header', :text)
  end

  def test_template_config_add_setting
    template_config(new_setting: 'value')
    assert_equal 'value', template_config(:new_setting)
  end

  def test_template_config_add_multiple_settings
    template_config(new_setting_1: '1', new_setting_2: '2')
    assert_equal '1', template_config(:new_setting_1)
    assert_equal '2', template_config(:new_setting_2)
  end

  def test_template_config_add_multiple_settings_by_mode
    template_config({'new_setting'=> 'value', another: 'ting'}, :html)
  end

  def test_template_config_missing_setting
    e = assert_raise MissingConfigError do
      template_config(:not_there)
    end
    assert_equal 'Missing config setting :not_there', e.message
  end

  def test_template_config_mode
    set_mode_text
    assert_equal :text, template_config(:mode)
  end

  def test_template_config_validation_pattern_not_string
    e = assert_raise InvalidConfigError do
      template_config(pattern: ['<%', '%>'])
    end
    assert_equal 'Value for setting :pattern must be a non-empty string', e.message
  end

  def test_template_config_validation_pattern_empty_string
    e = assert_raise InvalidConfigError do
      template_config(pattern: '')
    end
    assert_equal 'Value for setting :pattern must be a non-empty string', e.message
  end

  def test_template_config_validation_compact_non_boolean
    e = assert_raise InvalidConfigError do
      template_config(compact: 'true')
    end
    assert_equal 'Value for setting :compact must be a boolean', e.message
  end

  def test_template_config_validation_trim_non_boolean
    e = assert_raise InvalidConfigError do
      template_config(trim: 'false')
    end
    assert_equal 'Value for setting :trim must be a boolean', e.message
  end

  def test_template_config_validation_supported_modes_not_array
    e = assert_raise InvalidConfigError do
      template_config(supported_modes: 'text')
    end
    assert_equal 'Value for setting :supported_modes must be a non-empty array of symbols', e.message
  end

  def test_template_config_validation_supported_modes_empty_array
    e = assert_raise InvalidConfigError do
      template_config(supported_modes: [])
    end
    assert_equal 'Value for setting :supported_modes must be a non-empty array of symbols', e.message
  end

  def test_template_config_validation_supported_modes_array_containing_non_symbol
    e = assert_raise InvalidConfigError do
      template_config(supported_modes: [:text, 'html'])
    end
    assert_equal 'Value for setting :supported_modes must be a non-empty array of symbols', e.message
  end

  def test_template_config_validation_mode_unknown
    e = assert_raise InvalidConfigError do
      template_config(mode: :unknown)
    end
    assert_equal 'Unsupported mode :unknown, did you mean one of these? [:text, :html]', e.message
  end

  #
  # mode
  #

  def test_mode
    set_mode_text
    assert_true mode?(:text)
    set_mode_html
    assert_true mode?(:html)
  end

  def test_mode_as_function_no_arg
    e = assert_raise ArgumentError do
      mode?
    end
    assert_equal 'wrong number of arguments (given 0, expected 1)', e.message
  end

  #
  # header
  #

  def test_header
    set_mode_text
    assert_equal "<'title'>", header("<'title'>")
  end

  def test_header_escape_html
    set_mode_html
    assert_equal '<div class="field_header">&lt;&#39;title&#39;&gt;</div>', header("<'title'>")
  end

  def test_header_expected_attribute_unused
    set_mode_text
    template_config(text_header: '[[@caption]]')
    e = assert_raise UnusedAttributeError do
      header('title')
    end
    assert_equal 'Unused [[@caption]] attribute for config setting :text_header with value "[[@caption]]"', e.message
  end

  def test_header_unused_attribute
    set_mode_text
    template_config(text_header: '[[@title]] - [[@unused]]')
    e = assert_raise UnusedAttributeError do
      header('title')
    end
    assert_equal 'Unused [[@unused]] attribute for config setting :text_header with value "title - [[@unused]]"', e.message
  end

  def test_header_css
    set_mode_html
    assert_equal '<div class="css">title</div>', header('title', css: 'css')
  end

  def test_header_css_default
    set_mode_html
    assert_equal '<div class="field_header">title</div>', header('title')
  end

  def test_header_unexpected_attribute_ignored
    set_mode_text
    assert_equal 'title', header('title', css: 'text has no css')
  end

  def test_header_no_mode_set
    @template_config[:mode] = nil
    e = assert_raise InvalidModeError do
      header('Text')
    end
    assert_equal 'Templating mode not set, supported: [:text, :html]', e.message
  end

  #
  # field
  #

  def test_field
    set_mode_text
    assert_equal "<'label'>: <'value'>", field("<'label'>", "<'value'>")
  end

  def test_field_no_label
    set_mode_text
    assert_equal 'memo', field('memo')
    set_mode_html
    assert_equal '<div class="field_value">memo</div>', field('memo')
  end

  def test_field_with_new_lines
    set_mode_text
    assert_equal "label: line1\nline2\nline3", field('label', "line1\nline2\nline3")
    set_mode_html
    assert_equal '<div class="field_value"><span>label: </span>line1<br />line2<br />line3</div>',
      field('label', "line1\nline2\nline3")
  end

  def test_field_escape_html
    set_mode_html
    assert_equal '<div class="field_value"><span>&lt;&#39;label&#39;&gt;: </span>&lt;&#39;value&#39;&gt;</div>',
      field("<'label'>", "<'value'>")
  end

  def test_field_escape_html_no_label
    set_mode_html
    assert_equal '<div class="field_value">&lt;&#39;value&#39;&gt;</div>', field("<'value'>")
  end

  def test_field_with_css
    set_mode_html
    assert_equal '<div class="css"><span>label: </span>value</div>', field('label', 'value', css: 'css')
  end

  def test_field_no_label_with_css
    set_mode_html
    assert_equal '<div class="css">memo</div>', field('memo', css: 'css')
  end

  def test_field_unused_attribute
    set_mode_text
    template_config(text_field: '[[@caption]]: [[@result]]')
    e = assert_raise UnusedAttributeError do
      field('label', 'value')
    end
    assert_equal 'Unused [[@caption]] attribute for config setting :text_field with value "[[@caption]]: [[@result]]"', e.message
  end

  def test_field_empty
    set_mode_text
    assert_equal '', field('label', '')
    assert_equal '', field('label', '   ')
    set_mode_html
    assert_equal '<div class="field_empty"><span>label:</span></div>', field('label', '   ')
  end

  def test_field_empty_no_label
    set_mode_text
    assert_equal '', field('')
    set_mode_html
    assert_equal '<div class="field_empty"></div>', field('')
  end

  def test_field_empty_no_label_with_css
    set_mode_html
    assert_equal '<div class="css"></div>', field('', css: 'css')
  end

  def test_field_empty_with_css
    set_mode_html
    assert_equal '<div class="css"><span>label:</span></div>', field('label', '', css: 'css')
  end

  def test_field_empty_with_unused_attribute
    set_mode_text
    template_config(text_field_empty: '[[@unused]]')
    e = assert_raise UnusedAttributeError do
      field('label', '')
    end
    assert_equal 'Unused [[@unused]] attribute for config setting :text_field_empty with value "[[@unused]]"', e.message
  end

  def test_field_empty_with_unexpected_attribute_ignored
    set_mode_text
    assert_equal '', field('label', '', css: 'text has no css')
  end

  def test_field_missing
    set_mode_text
    assert_equal '', field('label', nil)
    set_mode_html
    assert_equal '<div class="field_empty"><span>label:</span></div>', field('label', nil)
  end

  def test_field_missing_no_label
    set_mode_text
    assert_equal '', field(nil)
    set_mode_html
    assert_equal '<div class="field_empty"></div>', field(nil)
  end

  def test_field_missing_no_label_with_css
    set_mode_html
    assert_equal '<div class="css"></div>', field(nil, css: 'css')
  end

  def test_field_missing_with_css
    set_mode_html
    assert_equal '<div class="css"><span>label:</span></div>', field('label', nil, css: 'css')
  end

  def test_field_missing_with_unused_attribute
    set_mode_text
    template_config(text_field_missing: '[[@unused]]')
    e = assert_raise UnusedAttributeError do
      field('label', nil)
    end
    assert_equal 'Unused [[@unused]] attribute for config setting :text_field_missing with value "[[@unused]]"', e.message
  end

  def test_field_missing_with_unexpected_attribute_ignored
    set_mode_text
    assert_equal '', field('label', nil, css: 'text has no css')
  end

  def test_field_at_char_in_value
    set_mode_text
    assert_equal 'label: someone@something.com', field('label', 'someone@something.com')
  end

  def test_field_attribute_in_between_words
    set_mode_html
    template_config(html_header: 'efforts[[@title]]fail')
    assert_equal 'effortsneverfail', header('never')
  end

  #
  # blocks
  #

  def test_block_begin
    set_mode_text
    assert_equal '', block_begin
    set_mode_html
    assert_equal '<div class="field_block">', block_begin
  end

  def test_block_begin_css
    set_mode_html
    assert_equal '<div class="css">', block_begin(css: 'css')
  end

  def test_block_begin_unused_attribute
    set_mode_text
    template_config(text_block_begin: '[[@unused]]')
    e = assert_raise UnusedAttributeError do
      block_begin
    end
    assert_equal 'Unused [[@unused]] attribute for config setting :text_block_begin with value "[[@unused]]"', e.message
  end

  def test_block_begin_missing_attribute_ignored
    set_mode_text
    assert_equal '', block_begin(css: 'text has no css')
  end

  def test_block_next
    set_mode_text
    assert_equal '', block_next
    set_mode_html
    assert_equal '</div><div class="field_block">', block_next
  end

  def test_block_next_css
    set_mode_html
    assert_equal '</div><div class="css">', block_next(css: 'css')
  end

  def test_block_next_unused_attribute
    set_mode_text
    template_config(text_block_next: '[[@unused]]')
    e = assert_raise UnusedAttributeError do
      block_next
    end
    assert_equal 'Unused [[@unused]] attribute for config setting :text_block_next with value "[[@unused]]"', e.message
  end

  def test_block_next_unexpected_attribute_ignored
    set_mode_text
    assert_equal '', block_next(css: 'text has no css')
  end

  def test_block_from_int_1
    set_mode_text
    assert_equal '', block_from_int(1)
    set_mode_html
    assert_equal '<div class="field_block">', block_from_int(1)
  end

  def test_block_from_int_1_css
    set_mode_html
    assert_equal '<div class="css">', block_from_int(1, css: 'css')
  end

  def test_block_from_int_1_unused_attribute
    set_mode_text
    template_config(text_block_begin: '[[@unused]]')
    e = assert_raise UnusedAttributeError do
      block_from_int(1)
    end
    assert_equal 'Unused [[@unused]] attribute for config setting :text_block_begin with value "[[@unused]]"', e.message
  end

  def test_block_from_int_1_unexpected_attribute_ignored
    set_mode_text
    assert_equal '', block_from_int(1, css: 'text has no css')
  end

  def test_block_from_int_2
    set_mode_text
    assert_equal '', block_from_int(2)
    set_mode_html
    assert_equal '</div><div class="field_block">', block_from_int(2)
  end

  def test_block_from_int_2_unused_attribute
    set_mode_text
    template_config(text_block_next: '[[@unused]]')
    e = assert_raise UnusedAttributeError do
      block_from_int(2)
    end
    assert_equal 'Unused [[@unused]] attribute for config setting :text_block_next with value "[[@unused]]"', e.message
  end

  def test_block_from_int_2_unexpected_attribute_ignored
    set_mode_text
    assert_equal '', block_from_int(2, css: 'text has no css')
  end

  def test_block_end
    set_mode_text
    assert_equal '', block_end
    set_mode_html
    assert_equal '</div><br />', block_end
  end

end
