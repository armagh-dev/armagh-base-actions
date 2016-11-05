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


require_relative '../../helpers/coverage_helper'

require 'test/unit'
require 'fakefs/safe'

require_relative '../../../lib/armagh/support/templating'

class TestTemplating < Test::Unit::TestCase

  def setup
    @template = 'template.erubis'
    @partial_template = 'partial_template.erubis'

    template = <<-end.gsub(/^\s+\| /, '')
      | {{=Armagh::Support::Templating.header 'Title'}}
      | {{-Armagh::Support::Templating.block_begin}}
      | {{=Armagh::Support::Templating.field 'Label', 'Value'}}
      | {{-Armagh::Support::Templating.block_next}}
      | {{=Armagh::Support::Templating.render_partial '#{@partial_template}'}}
      | {{-Armagh::Support::Templating.block_end}}
    end
    FakeFS { File.write(@template, template) }

    partial_template = <<-end.gsub(/^\s+\| /, '')
      | {{=Armagh::Support::Templating.header 'Partial'}}
      | {{=Armagh::Support::Templating.field 'Empty', ''}}
      | {{=Armagh::Support::Templating.field 'Missing', nil}}
    end
    FakeFS { File.write(@partial_template, partial_template) }

    @expected_text  = "Title\nLabel: Value\nPartial"
    @expected_html  = "<div class=\"field_header\">Title</div>\n<div><span>Label:</span>Value</div>\n<div class=\"field_header\">Partial</div>\n<div class=\"field_empty\"><span>Empty:</span></div>\n<div class=\"field_empty\"><span>Missing:</span></div>"
    @expected_array = [@expected_text, @expected_html]
  end

  def test_render_template_text
    assert_equal @expected_text, FakeFS { Armagh::Support::Templating.render_template(@template, :text) }
  end

  def test_render_template_html
    assert_equal @expected_html, FakeFS { Armagh::Support::Templating.render_template(@template, :html) }
  end

  def test_render_template_text_and_html
    assert_equal @expected_array, FakeFS { Armagh::Support::Templating.render_template(@template, :text, :html) }
  end

  def test_render_template_html_and_text
    assert_equal @expected_array, FakeFS { Armagh::Support::Templating.render_template(@template, :html, :text) }
  end

  def test_render_template_unknown_mode
    e = assert_raise Armagh::Support::Templating::InvalidModeError do
      Armagh::Support::Templating.render_template(@template, :unknown)
    end
    assert_equal 'Unknown mode(s) selected: [:unknown], supported: [:text, :html]', e.message
  end

  def test_render_template_missing_template
    e = assert_raise Armagh::Support::Templating::MissingTemplateError do
      Armagh::Support::Templating.render_template(nil, :text)
    end
    assert_equal 'Template file path cannot be blank', e.message
  end

  def test_render_template_argument_error
    FakeFS { File.write(@template, '{{=Armagh::Support::Templating.header}}') }
    e = assert_raise ArgumentError do
      FakeFS { Armagh::Support::Templating.render_template(@template, :text) }
    end
    assert_equal 'wrong number of arguments (given 0, expected 1..2)', e.message
  end

  def test_render_partial_with_context
    FakeFS { File.write('partial.erubis', "{{=@letter.inspect}}") }
    FakeFS { File.write(@template, '{{=@letter}}-{{=Armagh::Support::Templating.render_partial "partial.erubis", letter: @letter}}') }
    ['a', 'b', 'c'].each do |letter|
      assert_equal "#{letter}-#{letter.inspect}",
        FakeFS { Armagh::Support::Templating.render_template(@template, :text, letter: letter) }
    end
  end

  def test_render_partial_nested
    FakeFS { File.write('1.erubis', "Partial 1: {{=Armagh::Support::Templating.render_partial '2.erubis'}}") }
    FakeFS { File.write('2.erubis', "Partial 2: {{=Armagh::Support::Templating.render_partial '3.erubis'}}") }
    FakeFS { File.write('3.erubis', 'Partial 3: Success!') }
    FakeFS { File.write(@template, "Master: {{=Armagh::Support::Templating.render_partial '1.erubis'}}") }
    assert_equal 'Master: Partial 1: Partial 2: Partial 3: Success!',
      FakeFS { Armagh::Support::Templating.render_template(@template, :text) }
  end

  def test_header_no_mode_set
    e = assert_raise Armagh::Support::Templating::MissingConfigError do
      Armagh::Support::Templating.header('Text')
    end
    assert_equal 'Templating mode not set, supported: [:text, :html]', e.message
  end

  def test_template_config_get
    assert_equal '@title', Armagh::Support::Templating.template_config(:text_header)
  end

  def test_template_config_get_by_mode
    assert_equal '@title', Armagh::Support::Templating.template_config(:header, :text)
  end

  def test_template_config_get_string
    assert_equal '@title', Armagh::Support::Templating.template_config('text_header')
  end

  def test_template_config_get_string_by_mode
    assert_equal '@title', Armagh::Support::Templating.template_config('header', :text)
  end

  def test_template_config_set_new_component
    Armagh::Support::Templating.template_config(text_component: 'new')
    assert_equal 'new', Armagh::Support::Templating.template_config(:text_component)
  end

  def test_template_config_missing_setting
    e = assert_raise Armagh::Support::Templating::MissingConfigError do
      Armagh::Support::Templating.template_config(:not_there)
    end
    assert_equal 'Missing config setting :not_there', e.message
  end

  def test_template_config_mode
    Armagh::Support::Templating.template_config(mode: :text)
    assert_equal :text, Armagh::Support::Templating.template_config(:mode)
  end

  def test_mode
    Armagh::Support::Templating.template_config(mode: :html)
    assert_equal :html, Armagh::Support::Templating.template_config(:mode)
  end

  def test_header
    assert_equal Armagh::Support::Templating.template_config(:text_header), Armagh::Support::Templating.header('@title', :text)
  end

  def test_field_empty
    assert_equal Armagh::Support::Templating.template_config(:html_field_empty), Armagh::Support::Templating.field('@label', '   ', :html)
  end

  def test_field_missing
    assert_equal Armagh::Support::Templating.template_config(:html_field_missing), Armagh::Support::Templating.field('@label', nil, :html)
  end

  def test_block_begin
    assert_equal Armagh::Support::Templating.template_config(:html_block_begin), Armagh::Support::Templating.block_begin(:html)
  end

  def test_block_next
    assert_equal Armagh::Support::Templating.template_config(:html_block_next), Armagh::Support::Templating.block_next(:html)
  end

  def test_block_from_int_1
    assert_equal Armagh::Support::Templating.template_config(:html_block_begin), Armagh::Support::Templating.block_from_int(1, :html)
  end

  def test_block_from_int_2
    assert_equal Armagh::Support::Templating.template_config(:html_block_next), Armagh::Support::Templating.block_from_int(2, :html)
  end

  def test_block_end
    Armagh::Support::Templating.template_config(text_block_end: 'end')
    assert_equal 'end', Armagh::Support::Templating.block_end(:text)
  end

  private def binding_test
    'Binding was successful!'
  end

end
