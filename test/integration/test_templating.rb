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


require_relative '../helpers/coverage_helper'
require_relative '../helpers/fixture_helper'

require 'test/unit'

require_relative '../../lib/armagh/support/xml'
require_relative '../../lib/armagh/support/hash_doc'
require_relative '../../lib/armagh/support/templating'

class TestIntegrationTemplating < Test::Unit::TestCase
  include FixtureHelper
  include Armagh::Support::Templating

  def custom_address(hash)
    street   = hash['street']
    unit     = hash['unit']
    unit     = unit.empty? ? '' : "\nUnit #{hash['unit']}"
    city     = hash['city']
    county   = '( Some County )'
    statezip = "#{hash['state']}-#{hash['zip']}"
    field("#{street}#{unit}\n#{city} #{county}\n#{statezip}")
  end

  def setup
    set_fixture_dir('templating')
    config_values = {
      'xml' => {'html_nodes' => ['body.content']}
    }
    config = Armagh::Support::XML.create_configuration([], 'int_test', config_values)
    @data = Armagh::Support::XML.to_hash(fixture('data.xml'), config)
    @doc  = Armagh::Support::HashDoc.new(@data)
  end

  def test_render_template_text
    template_path = fixture_path('template.erubis')
    result = render_template(template_path, :text, doc: @doc)
    assert_equal fixture('template.erubis.text', result), result
  end

  def test_render_template_html
    template_path = fixture_path('template.erubis')
    result = render_template(template_path, :html, doc: @doc)
    assert_equal fixture('template.erubis.html', result), result
  end

  def test_render_template_text_and_html
    template_path = fixture_path('template.erubis')
    result = render_template(template_path, :text, :html, doc: @doc)
    assert_equal [fixture('template.erubis.text', result.first),
                  fixture('template.erubis.html', result.last)], result
  end

  def test_audit_nothing_rendered
    expected = {
      0=>["attr_id",
          "attr_total",
          "city",
          "description",
          "first",
          "item",
          "last",
          "last_order_date",
          "middle",
          "phone",
          "shipping_method",
          "state",
          "street",
          "test",
          "total_price",
          "unit",
          "zip"]}
    doc = Armagh::Support::HashDoc.new(@data)
    result = doc.audit {}
    assert_equal expected, result
  end

  def test_audit_render_text
    expected = {
      0=>["description", "phone", "test"],
      1=>["attr_id",
          "attr_total",
          "city",
          "customer",
          "data",
          "first",
          "last",
          "last_order_date",
          "middle",
          "notes",
          "order",
          "orders",
          "state",
          "street",
          "unit",
          "zip"],
      2=>["address", "item", "shipping_method", "total_price"]}
    doc = Armagh::Support::HashDoc.new(@data)
    result = doc.audit do
      render_template(fixture_path('template.erubis'), :text, doc: doc)
    end
    assert_equal expected, result
  end

  def test_audit_render_html
    expected = {
      0=>["description", "phone", "test"],
      1=>["attr_id",
          "attr_total",
          "city",
          "customer",
          "data",
          "first",
          "last",
          "last_order_date",
          "middle",
          "notes",
          "order",
          "orders",
          "state",
          "street",
          "unit",
          "zip"],
      2=>["address", "item", "shipping_method", "total_price"]}
    doc = Armagh::Support::HashDoc.new(@data)
    result = doc.audit do
      render_template(fixture_path('template.erubis'), :html, doc: doc)
    end
    assert_equal expected, result
  end

  def test_audit_render_text_html
    expected = {
      0=>["description", "phone", "test"],
      2=>["attr_id",
          "attr_total",
          "city",
          "customer",
          "data",
          "first",
          "last",
          "last_order_date",
          "middle",
          "notes",
          "order",
          "orders",
          "state",
          "street",
          "unit",
          "zip"],
      4=>["address", "item", "shipping_method", "total_price"]}
    doc = Armagh::Support::HashDoc.new(@data)
    result = doc.audit do
      render_template(fixture_path('template.erubis'), :text, :html, doc: doc)
    end
    assert_equal expected, result
  end

  def test_movie_template
    content = JSON.parse(fixture('movie.json')).dig('movie', 0)
    text, html = render_template(fixture_path('movie.erubis'), :text, :html, content: content)
    expected = [fixture('movie.erubis.text', text),
                fixture('movie.erubis.html', html)]
    assert_equal text, expected.first
    assert_equal html, expected.last
  end

end
