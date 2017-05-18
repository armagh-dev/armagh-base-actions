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

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../helpers/fixture_helper'
require_relative '../../../helpers/coverage_helper'
require_relative '../../../../lib/armagh/support/xml/splitter'

class TestXMLSplitter < Test::Unit::TestCase

  include FixtureHelper

  def setup
    set_fixture_dir('xml')
    @config = Armagh::Support::XML::Splitter.create_configuration([], 'xml', 'xml_splitter'=>{'repeated_element_name'=>'sdnEntry'})
  end

  def test_split_with_valid_xml_string
    xml = fixture('big_xml.xml')
    small_xmls = Armagh::Support::XML::Splitter.split_parts(xml, @config)
    expected_xmls = fixture('big_xml.xml.results.txt', small_xmls.to_s)
    assert_equal expected_xmls, small_xmls.to_s
  end

  def test_split_with_invalid_xml_array
    xml = [1, 2, 3]
    e = assert_raise Armagh::Support::XML::Splitter::XMLTypeError do
      Armagh::Support::XML::Splitter.split_parts(xml, @config)
    end
    assert_equal 'XML must be a string', e.message
  end

  def test_split_with_invalid_xml_empty
    xml = ''
    e = assert_raise Armagh::Support::XML::Splitter::XMLValueError do
      Armagh::Support::XML::Splitter.split_parts(xml, @config)
    end
    assert_equal 'XML cannot be nil or empty', e.message
  end

  def test_split_with_repeated_element_name_not_in_xml
    config = Armagh::Support::XML::Splitter.create_configuration([], 'xml', 'xml_splitter'=>{'repeated_element_name'=>'hello'})
    xml = fixture('big_xml.xml')
    e = assert_raise Armagh::Support::XML::Splitter::RepElemNameValueNotFound do
      Armagh::Support::XML::Splitter.split_parts(xml, config)
    end
    assert_equal 'Repeated element name must be present in XML', e.message
  end

  def test_split_with_exact_match
    config = Armagh::Support::XML::Splitter.create_configuration([], 'xml', 'xml_splitter'=>{'repeated_element_name'=>'bill'})
    xml = '<root><bill>Bill 1</bill><bill>Bill 2</bill></root>'
    expected_xmls = ['<root><bill>Bill 1</bill></root>', '<root><bill>Bill 2</bill></root>']
    small_xmls = Armagh::Support::XML::Splitter.split_parts(xml, config)
    assert_equal expected_xmls, small_xmls
  end

  def test_split_with_partial_match
    config = Armagh::Support::XML::Splitter.create_configuration([], 'xml', 'xml_splitter'=>{'repeated_element_name'=>'bill'})
    xml = "<root><billparty>Hello</billparty></root>"
    e = assert_raise Armagh::Support::XML::Splitter::RepElemNameValueNotFound do
      Armagh::Support::XML::Splitter.split_parts(xml, config)
    end
    assert_equal 'Repeated element name must be present in XML', e.message
  end

  def test_split_with_unexpected_errors
    xml = 'hello'
    xml.stubs(:split).raises(RuntimeError, 'fake message')
    e = assert_raise Armagh::Support::XML::Splitter::XMLSplitError do
      Armagh::Support::XML::Splitter.split_parts(xml, @config)
    end
    assert_equal 'fake message', e.message
  end

end
