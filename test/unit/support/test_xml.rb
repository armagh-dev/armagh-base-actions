# Copyright 2018 Noragh Analytics, Inc.
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
require 'fakefs/safe'

require_relative '../../helpers/coverage_helper'
require_relative '../../../lib/armagh/support/xml'
require_relative '../../../lib/armagh/support/xml/divider'

module XMLTestHelpers
  def combine_parts(parts)
    combined_parts = parts.inject("") do |str, part|
        part = remove_header_from_part(part) if !str.empty?
        part = remove_footer_from_part(part)
        str << part
      end
    combined_parts << @footer
  end

  def remove_footer_from_part(part)
    lines = part.lines
    last_line_from_part = lines.pop
    @footer ||= last_line_from_part
    lines.join
  end

  def remove_header_from_part(part)
    header_lines = []
    complete_header = false

    part.lines.each do |line|
      if !line.match(/\s*sdnEntry/) && complete_header == false
        header_lines << line
      else
        complete_header = true
        next
      end
    end

    lines = part.lines - header_lines
    lines.join()
  end
end

class TestXML < Test::Unit::TestCase
  include XMLTestHelpers

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

    fixtures_path = File.join(__dir__, '..', '..', 'fixtures', 'xml')

    @big_xml = File.join fixtures_path, 'big_xml.xml'
    @collected_big_xml = stub(:collected_doc)
    @collected_big_xml.stubs(:collected_file).returns(@big_xml)
    @expected_divided_content = [
      "<?xml version=\"1.0\" standalone=\"yes\"?>\r\n<sdnList xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://tempuri.org/sdnList.xsd\">\r\n  <publshInformation>\r\n    <Publish_Date>05/30/2014</Publish_Date>\r\n    <Record_Count>5931</Record_Count>\r\n  </publshInformation>\r\n  <sdnEntry>\r\n    <uid>10</uid>\r\n    <lastName>ABASTECEDORA NAVAL Y INDUSTRIAL, S.A.</lastName>\r\n    <sdnType>Entity</sdnType>\r\n    <programList>\r\n      <program>CUBA</program>\r\n    </programList>\r\n    <akaList>\r\n      <aka>\r\n        <uid>4</uid>\r\n        <type>a.k.a.</type>\r\n        <category>strong</category>\r\n        <lastName>ANAINSA</lastName>\r\n      </aka>\r\n    </akaList>\r\n    <addressList>\r\n      <address>\r\n        <uid>7</uid>\r\n        <country>Panama</country>\r\n      </address>\r\n    </addressList>\r\n  </sdnEntry>\r\n</sdnList>\r\n",
      "<?xml version=\"1.0\" standalone=\"yes\"?>\r\n<sdnList xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://tempuri.org/sdnList.xsd\">\r\n  <publshInformation>\r\n    <Publish_Date>05/30/2014</Publish_Date>\r\n    <Record_Count>5931</Record_Count>\r\n  </publshInformation>\r\n  <sdnEntry>\r\n    <uid>15</uid>\r\n    <firstName>Nury de Jesus</firstName>\r\n    <lastName>ABDELNUR</lastName>\r\n    <sdnType>Individual</sdnType>\r\n    <programList>\r\n      <program>CUBA</program>\r\n    </programList>\r\n    <addressList>\r\n      <address>\r\n        <uid>12</uid>\r\n        <country>Panama</country>\r\n      </address>\r\n    </addressList>\r\n  </sdnEntry>\r\n</sdnList>\r\n",
      "<?xml version=\"1.0\" standalone=\"yes\"?>\r\n<sdnList xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://tempuri.org/sdnList.xsd\">\r\n  <publshInformation>\r\n    <Publish_Date>05/30/2014</Publish_Date>\r\n    <Record_Count>5931</Record_Count>\r\n  </publshInformation>\r\n  <sdnEntry>\r\n    <uid>25</uid>\r\n    <lastName>ACEFROSTY SHIPPING CO., LTD.</lastName>\r\n    <sdnType>Entity</sdnType>\r\n    <programList>\r\n      <program>CUBA</program>\r\n    </programList>\r\n    <addressList>\r\n      <address>\r\n        <uid>16</uid>\r\n        <address1>171 Old Bakery Street</address1>\r\n        <city>Valletta</city>\r\n        <country>Malta</country>\r\n      </address>\r\n    </addressList>\r\n  </sdnEntry>\r\n</sdnList>\r\n",
      "<?xml version=\"1.0\" standalone=\"yes\"?>\r\n<sdnList xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://tempuri.org/sdnList.xsd\">\r\n  <publshInformation>\r\n    <Publish_Date>05/30/2014</Publish_Date>\r\n    <Record_Count>5931</Record_Count>\r\n  </publshInformation>\r\n  <sdnEntry>\r\n    <uid>36</uid>\r\n    <lastName>AEROCARIBBEAN AIRLINES</lastName>\r\n    <sdnType>Entity</sdnType>\r\n    <programList>\r\n      <program>CUBA</program>\r\n    </programList>\r\n    <akaList>\r\n      <aka>\r\n        <uid>12</uid>\r\n        <type>a.k.a.</type>\r\n        <category>strong</category>\r\n        <lastName>AERO-CARIBBEAN</lastName>\r\n      </aka>\r\n    </akaList>\r\n    <addressList>\r\n      <address>\r\n        <uid>25</uid>\r\n        <city>Havana</city>\r\n        <country>Cuba</country>\r\n      </address>\r\n    </addressList>\r\n  </sdnEntry>\r\n</sdnList>\r\n",
      "<?xml version=\"1.0\" standalone=\"yes\"?>\r\n<sdnList xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://tempuri.org/sdnList.xsd\">\r\n  <publshInformation>\r\n    <Publish_Date>05/30/2014</Publish_Date>\r\n    <Record_Count>5931</Record_Count>\r\n  </publshInformation>\r\n  <sdnEntry>\r\n    <uid>39</uid>\r\n    <lastName>AEROTAXI EJECUTIVO, S.A.</lastName>\r\n    <sdnType>Entity</sdnType>\r\n    <programList>\r\n      <program>CUBA</program>\r\n    </programList>\r\n    <addressList>\r\n      <address>\r\n        <uid>27</uid>\r\n        <city>Managua</city>\r\n        <country>Nicaragua</country>\r\n      </address>\r\n    </addressList>\r\n  </sdnEntry>\r\n  <sdnEntry></sdnEntry>\r\n</sdnList>\r\n",
      "<?xml version=\"1.0\" standalone=\"yes\"?>\r\n<sdnList xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://tempuri.org/sdnList.xsd\">\r\n  <publshInformation>\r\n    <Publish_Date>05/30/2014</Publish_Date>\r\n    <Record_Count>5931</Record_Count>\r\n  </publshInformation>\r\n  <sdnEntry id=\"124\">\r\n    <uid>42</uid>\r\n    <lastName>MR. COOL</lastName>\r\n    <sdnType>Entity</sdnType>\r\n    <programList>\r\n      <program>ABC</program>\r\n    </programList>\r\n    <addressList>\r\n      <address>\r\n        <uid>1</uid>\r\n        <city>Mumbai</city>\r\n        <country>India</country>\r\n      </address>\r\n    </addressList>\r\n  </sdnEntry>\r\n  <sdnEntry id=\"125\" firstName=\"John\" lastName=\"McLane\"></sdnEntry>\r\n</sdnList>\r\n"
    ]

    @config_store = []
    @config_size_default = Armagh::Support::XML.create_configuration( @config_store, 'def', {'xml' => {'html_nodes' => ['body.content']}} )
    @config_size_800     = Armagh::Support::XML::Divider.create_configuration( @config_store, 's800',  {'xml_divide' => { 'size_per_part'  => 800,  'xml_element' => 'sdnEntry' }})
    @config_size_1000    = Armagh::Support::XML::Divider.create_configuration( @config_store, 's1000', {'xml_divide' => { 'size_per_part'  => 1000, 'xml_element' => 'sdnEntry' }})
  end

  def teardown
    FakeFS::FileSystem.clear
  end

  def test_html_node
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
    expected = {"book"=>{"authors"=>{"name"=>["Someone","Sometwo"]},"chapters"=>{"chapter"=>[{"attr_key"=>"chappy","body.content"=>"<style>\n      body {\n        font-size: 10pt;\n        color: #777;\n      }\n    </style>\n    <p>Treat this section like text</p>\n    <div>\n      <span>\n        as-is without parsing to a hash\n      </span>\n    </div>","number"=>"1","title"=>"A Fine Beginning"},{"number"=>"2","title"=>"A Terrible End"}]},"data"=>"Some Data","title"=>"Book Title"}}
    assert_equal expected, Armagh::Support::XML.to_hash(xml, @config_size_default.xml.html_nodes)
    assert_equal expected, Armagh::Support::XML.to_hash(xml, @config_size_default.xml.html_nodes.first)
  end

  def test_to_hash
    assert_equal @expected, Armagh::Support::XML.to_hash(@xml, @config_size_default.xml.html_nodes)
  end

  def test_to_hash_repeating_nodes_attrs_and_text
    xml = '<xml><div id="123" class="css">stuff</div><div id="124" class="css2">more stuff</div><div>just text</div></xml>'
    expected = {"xml"=>{"div"=>[{"attr_class"=>"css","attr_id"=>"123","text"=>"stuff"},{"attr_class"=>"css2","attr_id"=>"124","text"=>"more stuff"},"just text"]}}
    assert_equal expected, Armagh::Support::XML.to_hash(xml, @config_size_default.xml.html_nodes)
  end

  def test_to_hash_multiline_nodes
    xml = <<-end
      <xml>
        <div id="123" class="css">
          <p>some text</p>
          <p>some other text</p>
        </div>
        <div id="124" class="css2">more stuff</div>
        <div>just text</div>
      </xml>
    end
    expected = {"xml"=> {"div"=> [{"attr_id"=>"123", "attr_class"=>"css", "p"=>["some text", "some other text"]}, {"attr_id"=>"124", "attr_class"=>"css2", "text"=>"more stuff"}, "just text"]}}
    assert_equal expected, Armagh::Support::XML.to_hash(xml, @config_size_default.xml.html_nodes)
  end

  def test_to_hash_multiline_single_nodes
    xml = <<-end
      <xml>
        <div id="123" class="css">
          <p>some text
             some other text
          </p>
        </div>
        <div id="124" class="css2">more stuff</div>
        <div>just text</div>
      </xml>
    end
    expected = {"xml"=> {"div"=> [{"attr_id"=>"123", "attr_class"=>"css", "p"=>"some text some other text"}, {"attr_id"=>"124", "attr_class"=>"css2", "text"=>"more stuff"}, "just text"]}}
    assert_equal expected, Armagh::Support::XML.to_hash(xml, @config_size_default.xml.html_nodes)
  end

  def test_to_hash_bad_xml
    expected = {"bad"=>{"attr_"=>"", "attr_xml"=>""}}
    assert_equal expected, Armagh::Support::XML.to_hash('<bad xml <', @config_size_default.xml.html_nodes)
  end

  def test_to_hash_not_xml
    e = assert_raise Armagh::Support::XML::Parser::XMLParseError do
      Armagh::Support::XML.to_hash('this is not XML', @config_size_default.xml.html_nodes)
    end
    assert_equal 'Attempting to apply text to an empty stack', e.message
  end

  def test_to_hash_missmatched_input
    e = assert_raise Armagh::Support::XML::Parser::XMLParseError do
      Armagh::Support::XML.to_hash({hash_instead_of_string: true}, @config_size_default.xml.html_nodes)
    end
    assert_equal 'no implicit conversion of Hash into String', e.message
  end

  def test_file_to_hash
    result = ''
    FakeFS {
      File.open('sample.xml', 'w') { |f| f << @xml }
      result = Armagh::Support::XML.file_to_hash('sample.xml', @config_size_default.xml.html_nodes)
    }
    assert_equal @expected, result
  end

  def test_file_to_hash_missing_file
    e = assert_raise Armagh::Support::XML::Parser::XMLParseError do
      Armagh::Support::XML.file_to_hash('missing.file', @config_size_default.xml.html_nodes)
    end
    assert_equal 'No such file or directory @ rb_sysopen - missing.file', e.message
  end

  def test_file_to_hash_nil_html_nodes
    result = ''
    FakeFS {
      File.open('sample.xml', 'w') { |f| f << @xml }
      result = Armagh::Support::XML.file_to_hash('sample.xml', nil)
    }
    assert_equal @expected, result
  end

  def test_html_to_hash
    html = '<html><body><p>Text</p></body></html>'
    expected = {"html"=>{"body"=>{"p"=>"Text"}}}
    assert_equal expected, Armagh::Support::XML.html_to_hash(html)
  end

  def test_html_multiline_node
    html = <<-end
      <html>
        <body>
          <ul>
            <li>One</li>
            <li>Two</li>
            <li>Three</li>
          </ul>
        </body>
      </html>
    end
    expected = {"html"=>{"body"=>{"ul"=>{"li"=>["One", "Two", "Three"]}}}}
    assert_equal expected, Armagh::Support::XML.html_to_hash(html)
  end

  def test_html_multiline_single_node
    html = <<-end
      <html>
        <body>
          <ul>
            <li>
              One
              Two
              Three
            </li>
          </ul>
        </body>
      </html>
    end
    expected = {"html"=>{"body"=>{"ul"=>{"li"=>"One Two Three"}}}}
    assert_equal expected, Armagh::Support::XML.html_to_hash(html)
  end

  def test_html_to_hash_with_attributes
    html = '<html><body><form id="form123"><input name="username" value="anonymous" /></form></body></html>'
    expected = {"html"=>{"body"=>{"form"=>{"attr_id"=>"form123","input"=>{"attr_name"=>"username","attr_value"=>"anonymous"}}}}}
    assert_equal expected, Armagh::Support::XML.html_to_hash(html)
  end

  def test_html_to_hash_invalid
    e = assert_raise Armagh::Support::XML::Parser::XMLParseError do
      Armagh::Support::XML.html_to_hash('<html<body<pText')
    end
    assert_include e.message, 'invalid format'
  end

  test "divides source xml into array of multiple xml strings having max size of 'size_per_part' bytes" do
    actual_divided_content = []

    Armagh::Support::XML.divided_parts(@collected_big_xml, @config_size_1000) do |part|
      actual_divided_content << part
    end

    assert_equal @expected_divided_content, actual_divided_content
    assert_equal false, actual_divided_content.map(&:size).any? { |x| x > @config_size_1000.xml_divide.size_per_part }
  end

  test "when xml is well-formed, divided parts match source xml when recombined" do
    expected_combined_content = IO.binread(@collected_big_xml.collected_file)
    divided_content = []

    Armagh::Support::XML.divided_parts(@collected_big_xml, @config_size_1000) do |part|
      divided_content << part
    end
    combined_parts = combine_parts(divided_content)

    assert_equal expected_combined_content, combined_parts
  end

  test "returns an error when size_per_part is smaller than largest divided part" do
    divided_content = []

    assert_raise Armagh::Support::XML::Divider::MaxSizeTooSmallError do
      Armagh::Support::XML.divided_parts(@collected_big_xml, @config_size_800) do |part|
        divided_content << part
      end
    end
  end
end

