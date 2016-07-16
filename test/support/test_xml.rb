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

require_relative '../coverage_helper'

require 'test/unit'
require 'fakefs/safe'

require_relative '../../lib/armagh/support/xml'

class TestXML < Test::Unit::TestCase
  def setup
    @xml = <<-end.gsub(/^\s+\|/, '')
      |<?xml version="1.0"?>
      | <book>
      |  <data><![CDATA[Some Data]]></data>
      |  <authors>
      |    <name>Someone</name>
      |    <name>Sometwo</name>
      |  </authors>
      |  <title>Book Title</title>
      |  <chapters>
      |    <chapter key='chappy'>
      |      <number>1</number>
      |      <title>A Fine Beginning</title>
      |    </chapter>
      |    <chapter>
      |      <number>2</number>
      |      <title>A Terrible End</title>
      |    </chapter>
      |  </chapters>
      |</book>
    end
    @expected = {"book"=>{"authors"=>{"name"=>["Someone","Sometwo"]},"chapters"=>{"chapter"=>[{"attr_key"=>"chappy","number"=>"1","title"=>"A Fine Beginning"},{"number"=>"2","title"=>"A Terrible End"}]},"data"=>"Some Data","title"=>"Book Title"}}
  end

  def test_text_node
    xml = @xml.sub(/<\/chapter>/, <<-end.gsub(/^\s+\|/, '')
      |  <body.content>
      |    <style>
      |      body {
      |        font-size: 10pt;
      |        color: #777;
      |      }
      |    </style>
      |    <p>Treat this section like text</p>
      |    <div>
      |      <span>
      |        as-is without parsing to a hash
      |      </span>
      |    </div>
      |  </body.content>
      |</chapter>
    end
    )
    expected = {"book"=>{"authors"=>{"name"=>["Someone","Sometwo"]},"chapters"=>{"chapter"=>[{"attr_key"=>"chappy","body_content"=>"\n    <style>\n      body {\n        font-size: 10pt;\n        color: #777;\n      }\n    </style>\n    <p>Treat this section like text</p>\n    <div>\n      <span>\n        as-is without parsing to a hash\n      </span>\n    </div>\n  ","number"=>"1","title"=>"A Fine Beginning"},{"number"=>"2","title"=>"A Terrible End"}]},"data"=>"Some Data","title"=>"Book Title"}}
    assert_equal expected, Armagh::Support::XML.to_hash(xml, 'body.content')
  end

  def test_to_hash
    assert_equal @expected, Armagh::Support::XML.to_hash(@xml)
  end

  def test_to_hash_repeating_nodes_attrs_and_text
    xml = '<xml><div id="123" class="css">stuff</div><div id="124" class="css2">more stuff</div><div>just text</div></xml>'
    expected = {"xml"=>{"div"=>[{"attr_class"=>"css","attr_id"=>"123","text"=>"stuff"},{"attr_class"=>"css2","attr_id"=>"124","text"=>"more stuff"},"just text"]}}
    assert_equal expected, Armagh::Support::XML.to_hash(xml)
  end

  def test_to_hash_invalid_element_names
    xml = '<xml><$node>value</$node><body.content>stuff</body.content></xml>'
    expected = {"xml"=>{"_node"=>"value","body_content"=>"stuff"}}
    assert_equal expected, Armagh::Support::XML.to_hash(xml)
  end

  def test_to_hash_bad_xml
    expected = {"bad"=>{"attr_"=>"", "attr_xml"=>""}}
    assert_equal expected, Armagh::Support::XML.to_hash('<bad xml <')
  end

  def test_to_hash_not_xml
    e = assert_raise Armagh::Support::XML::XMLParseError do
      Armagh::Support::XML.to_hash('this is not XML')
    end
    assert_equal 'Attempting to apply text to an empty stack', e.message
  end

  def test_to_hash_missmatched_input
    e = assert_raise Armagh::Support::XML::XMLParseError do
      Armagh::Support::XML.to_hash({hash_instead_of_string: true})
    end
    assert_equal 'no implicit conversion of Hash into String', e.message
  end

  def test_file_to_hash
    result = ''
    FakeFS {
      File.open('sample.xml', 'w') { |f| f << @xml }
      result = Armagh::Support::XML.file_to_hash('sample.xml')
    }
    assert_equal @expected, result
  end

  def test_file_to_hash_missing_file
    e = assert_raise Armagh::Support::XML::XMLParseError do
      Armagh::Support::XML.file_to_hash('missing.file')
    end
    assert_equal 'No such file or directory @ rb_sysopen - missing.file', e.message
  end

  def test_html_to_hash
    html = '<html><body><p>Text</p></body></html>'
    expected = {"html"=>{"body"=>{"p"=>"Text"}}}
    assert_equal expected, Armagh::Support::XML.html_to_hash(html)
  end

  def test_html_to_hash_with_attributes
    html = '<html><body><form id="form123"><input name="username" value="anonymous" /></form></body></html>'
    expected = {"html"=>{"body"=>{"form"=>{"attr_id"=>"form123","input"=>{"attr_name"=>"username","attr_value"=>"anonymous"}}}}}
    assert_equal expected, Armagh::Support::XML.html_to_hash(html)
  end

  def test_html_to_hash_invalid
    e = assert_raise Armagh::Support::XML::XMLParseError do
      Armagh::Support::XML.html_to_hash('<html<body<pText')
    end
    assert_equal 'invalid format, document not terminated at line 1, column 24 [parse.c:831]', e.message.strip
  end
end
