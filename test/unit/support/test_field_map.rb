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
require 'mocha/test_unit'

require_relative '../../../lib/armagh/support/field_map'
require_relative '../../../lib/armagh/documents/action_document'
require_relative '../../../lib/armagh/documents/source'

class TestFieldMap < Test::Unit::TestCase
  include Armagh::Support::FieldMap

  def setup
    @now = Time.now

    config_values = {
      'field_map' => {
        'get_doc_id_from'        => '["account", "account_number"]',
        'get_doc_timestamp_from' => '["timestamp"]',
        'get_doc_copyright_from' => '["copyright"]',
        'get_doc_title_from'     => '["title"]'
      }
    }
    @config = Armagh::Support::FieldMap.create_configuration( [], 'test', config_values )

    @content = {
      'account' => {
        'account_number' => '101',
        'name'           => 'Brian',
        'email'          => 'brian@example.com',
        'phone'          => '555-1212',
      },
      'timestamp'      => @now - 7 * 24 * 60 * 60,
      'copyright'      => "Copyright (c) 2016",
      'title'          => "Some Content Title"
    }

    @metadata = {
      'copyright' => 'Metadata Copyright'
    }

    @source = Armagh::Documents::Source.new(filename: 'source_file.json', mtime: @now - 1 * 24 * 60 * 60)

    @doc = Armagh::Documents::ActionDocument.new(
      document_id: 'doc document_id',
      title:       'doc title',
      copyright:   'doc copyright',
      content:     @content,
      raw:         nil,
      metadata:    @metadata,
      docspec:     nil,
      source:      @source,
      document_timestamp: @now
    )
  end


  test "get_field_map_attr should return nil when content is nil" do
    assert_nil get_field_map_attr(nil, ['key'])
  end

  test "get_field_map_attr should return nil when hpath is nil or empty" do
    assert_nil get_field_map_attr({}, nil), 'get_field_map_attr should return nil when hpath is nil'
    assert_nil get_field_map_attr({}, [] ), 'get_field_map_attr should return nil when hpath is empty'
  end

  test "get_field_map_attr should return nil when hpath is not in content" do
    content = {
      'lock' => 'smith',
    }

    assert_nil get_field_map_attr(content, ['key'])
  end

  test "get_field_map_attr should return nil when it finds a nil value" do
    content = {
      'NilClass' => nil,
    }

    assert_nil get_field_map_attr(content, ['NilClass'])
  end

  test "get_field_map_attr should return the proper Time when it finds a Time value" do
    content = {
      'a Time' => @now,
    }

    attr = get_field_map_attr(content, ['a Time'])

    assert_kind_of Time, attr
    assert_equal   @now, attr
  end

  test "get_field_map_attr should return proper String when it finds a non-Time value" do
    content = {
      'String'     => 'string',
      'int'        => 10,
      'float'      => 10.1,
      'TrueClass'  => true,
      'FalseClass' => false,
      'Hash'       => { 'key' => 'val' },
      'Array'      => [ 1, 2, 3 ],
      'Object'     => Object.new,
      'Regexp'     => /hi there/,
      'Doc'        => @doc,
    }

    content.each do |key, val|
      assert_equal val.to_s, get_field_map_attr(content, [key])
    end
  end

  test "get_field_map_attr should not convert String key to Symbol or Symbol key to String" do
    content = {
      'String' => 'val for String',
      :Symbol  => 'val for Symbol',
    }

    assert_equal content['String'], get_field_map_attr(content, ['String']), "get_field_map_attr should have found String key 'String' given ['String']"
    assert_equal content[:Symbol],  get_field_map_attr(content, [:Symbol ]), "get_field_map_attr should have found Symbol key :Symbol given [:Symbol]"

    assert_nil get_field_map_attr(content, [:String ]), "get_field_map_attr should not have found String key 'String' given [:String]"
    assert_nil get_field_map_attr(content, ['Symbol']), "get_field_map_attr should not have found Symbol key :Symbol given ['Symbol']"
  end

  test "get_field_map_attr should strip Strings" do
    str = "Hi  There"
    content = {
      'left'  => "    #{str}",
      'right' => "#{str}      ",
      'both'  => "    #{str}      ",
    }

    content.each do |key, val|
      assert_equal str, get_field_map_attr(content, [key]), "get_field_map_attr should have stripped Strings"
    end
  end

  test "get_field_map_attr should find nested hpaths, including array elements" do
    content = {
      'key 1' => 'val 1',
      'key 2' => 'val 2',
      'key 3' => {
        'key 3.1' => 'val 3.1',
        'key 3.2' => 'val 3.2',
        'key 3.3' => {
          'key 3.3.1' => 'val 3.3.1',
          'key 3.3.2' => 'val 3.3.2',
          'key 3.3.3' => [
            'array 3.3.3.0',
            'array 3.3.3.1',
            'array 3.3.3.2',
            {
              'key 3.3.3.3.1' => 'val 3.3.3.3.1',
              'key 3.3.3.3.2' => 'val 3.3.3.3.2',
              'key 3.3.3.3.3' => [
                [
                  {
                    'key 3.3.3.3.3.0.0' => 'nested array value 3.3.3.3.3.0.0'
                  },
                ],
                {
                  'key 3.3.3.3.3.1' => 'val 3.3.3.3.3.1'
                },
                [
                  {
                    'key 3.3.3.3.3.2.0' => 'nested array value 3.3.3.3.3.2.0'
                  },
                  {
                    'key 3.3.3.3.3.2.1' => 'nested array value 3.3.3.3.3.2.1'
                  },
                ],
              ],
            },
            'array 3.3.3.4',
          ],
        },
      },
    }

    expected = {
      ['key 2']                                                => 'val 2',
      ['key 3', 'key 3.2']                                     => 'val 3.2',
      ['key 3', 'key 3.3', 'key 3.3.2']                        => 'val 3.3.2',
      ['key 3', 'key 3.3', 'key 3.3.3',  '0']                  => 'array 3.3.3.0',
      ['key 3', 'key 3.3', 'key 3.3.3',  '2']                  => 'array 3.3.3.2',
      ['key 3', 'key 3.3', 'key 3.3.3', '-1']                  => 'array 3.3.3.4',
      ['key 3', 'key 3.3', 'key 3.3.3', '-5']                  => 'array 3.3.3.0',
      ['key 3', 'key 3.3', 'key 3.3.3',  '3', 'key 3.3.3.3.2'] => 'val 3.3.3.3.2',
      ['key 3', 'key 3.3', 'key 3.3.3',       'key 3.3.3.3.2'] => 'val 3.3.3.3.2',
      ['key 3', 'key 3.3', 'key 3.3.3',  '3', 'key 3.3.3.3.3', '1', 'key 3.3.3.3.3.1'] => 'val 3.3.3.3.3.1',
      ['key 3', 'key 3.3', 'key 3.3.3',       'key 3.3.3.3.3', '1', 'key 3.3.3.3.3.1'] => 'val 3.3.3.3.3.1',
      ['key 3', 'key 3.3', 'key 3.3.3',       'key 3.3.3.3.3',      'key 3.3.3.3.3.1'] => 'val 3.3.3.3.3.1',
      ['key 3', 'key 3.3', 'key 3.3.3',  '3', 'key 3.3.3.3.3', '2', '1', 'key 3.3.3.3.3.2.1'] => 'nested array value 3.3.3.3.3.2.1',
      ['key 3', 'key 3.3', 'key 3.3.3',       'key 3.3.3.3.3', '2', '1', 'key 3.3.3.3.3.2.1'] => 'nested array value 3.3.3.3.3.2.1',
      ['key 3', 'key 3.3', 'key 3.3.3',       'key 3.3.3.3.3', '2',      'key 3.3.3.3.3.2.1'] => 'nested array value 3.3.3.3.3.2.1',
      ['key 3', 'key 3.3', 'key 3.3.3',       'key 3.3.3.3.3',           'key 3.3.3.3.3.2.1'] => 'nested array value 3.3.3.3.3.2.1',
    }
    expected_nil = [
      ['key 2', '2'],
      ['key 2', 'key 2.2'],
      ['key 3', 'key 3.2', '2'],
      ['key 3', 'key 3.2', 'key 3.2.2'],
      ['key 3', 'key 3.3', 'key 3.3.2', '2'],
      ['key 3', 'key 3.3', 'key 3.3.2', 'key 3.3.2.2'],
      ['key 3', 'key 3.3', 'key 3.3.3',  '2', '2'],
      ['key 3', 'key 3.3', 'key 3.3.3',  '2', 'key 3.3.2.2'],
      ['key 3', 'key 3.3', 'key 3.3.3', '-1', '2'],
      ['key 3', 'key 3.3', 'key 3.3.3', '-1', 'key 3.3.2.2'],
      ['key 3', 'key 3.3', 'key 3.3.3',  '3', 'key 3.3.3.3.2', '2'],
      ['key 3', 'key 3.3', 'key 3.3.3',  '3', 'key 3.3.3.3.2', 'key 3.3.3.3.2.2'],
      ['key 5'],
      ['key 3', 'key 3.5'],
      ['key 3', 'key 3.3', 'key 3.3.5'],
      ['key 3', 'key 3.3', 'key 3.3.3',  '5'],
      ['key 3', 'key 3.3', 'key 3.3.3', '-6'],
      ['key 3', 'key 3.3', 'key 3.3.3',  'Not An Integer'],
      ['key 3', 'key 3.3', 'key 3.3.3',  '1.2'],
      ['key 3', 'key 3.3', 'key 3.3.3',  '3', 'key 3.3.3.3.5'],
      ['key 3', 'key 3.3', 'key 3.3.3',       'key 3.3.3.3.3',      '1', 'key 3.3.3.3.3.2.1'],
    ]

    expected.each do |hpath, val|
      assert_equal val, get_field_map_attr(content, hpath), "get_field_map_attr for #{hpath} should have returned #{val}"
    end

    expected_nil.each do |hpath|
      assert_nil get_field_map_attr(content, hpath), "get_field_map_attr for #{hpath} should have been nil"
    end
  end


  test "set_field_map_attrs should not fail when doc is nil" do
    set_field_map_attrs(nil, @config)
  end

  test "set_field_map_attrs should do nothing when doc attrs exist and no config" do
    doc = @doc.dup

    set_field_map_attrs(doc, nil)

    assert_equal @doc.document_id,        doc.document_id
    assert_equal @doc.title,              doc.title
    assert_equal @doc.copyright,          doc.copyright
    assert_equal @doc.document_timestamp, doc.document_timestamp
  end

  test "set_field_map_attrs should do nothing when doc attrs exist and config does not have field_map" do
    doc = @doc.dup

    config_values = {}
    config = Armagh::Support::FieldMap.create_configuration( [], 'test', config_values )

    set_field_map_attrs(doc, config)

    assert_equal @doc.document_id,        doc.document_id
    assert_equal @doc.title,              doc.title
    assert_equal @doc.copyright,          doc.copyright
    assert_equal @doc.document_timestamp, doc.document_timestamp
  end

  test "set_field_map_attrs should do nothing when doc attrs exist and config does not have field_map maps" do
    doc = @doc.dup

    config_values = {
      'field_map' => {
      }
    }
    config = Armagh::Support::FieldMap.create_configuration( [], 'test', config_values )

    set_field_map_attrs(doc, config)

    assert_equal @doc.document_id,        doc.document_id
    assert_equal @doc.title,              doc.title
    assert_equal @doc.copyright,          doc.copyright
    assert_equal @doc.document_timestamp, doc.document_timestamp
  end

  test "set_field_map_attrs should do nothing when doc attrs exist, but content does not have field_maps" do
    doc = @doc.dup
    doc.content = {
      'nested' => @content,
    }

    set_field_map_attrs(doc, @config)

    assert_equal @doc.document_id,        doc.document_id
    assert_equal @doc.title,              doc.title
    assert_equal @doc.copyright,          doc.copyright
    assert_equal @doc.document_timestamp, doc.document_timestamp
  end

  test "set_field_map_attrs should set doc attrs from content" do
    doc = @doc.dup

    assert_not_equal @content['account']['account_number'], doc.document_id,        'pre-condition'
    assert_not_equal @content['title'],                     doc.title,              'pre-condition'
    assert_not_equal @content['copyright'],                 doc.copyright,          'pre-condition'
    assert_not_equal @content['timestamp'],                 doc.document_timestamp, 'pre-condition'

    set_field_map_attrs(doc, @config)

    assert_equal @content['account']['account_number'], doc.document_id
    assert_equal @content['title'],                     doc.title
    assert_equal @content['copyright'],                 doc.copyright
    assert_equal @content['timestamp'],                 doc.document_timestamp
  end

  test "set_field_map_attrs should set only the specified field_map doc attrs from content" do
    doc = @doc.dup

    config_values = {
      'field_map' => {
        'get_doc_id_from'        => '["account", "account_number"]',
        'get_doc_title_from'     => '["title"]'
      }
    }
    config = Armagh::Support::FieldMap.create_configuration( [], 'test', config_values )

    assert_not_equal @content['account']['account_number'], doc.document_id, 'pre-condition'
    assert_not_equal @content['title'],                     doc.title,       'pre-condition'

    set_field_map_attrs(doc, config)

    assert_equal @content['account']['account_number'], doc.document_id
    assert_equal @content['title'],                     doc.title
    assert_equal @doc.copyright,                        doc.copyright
    assert_equal @doc.document_timestamp,               doc.document_timestamp
  end

  test "set_field_map_attrs should set document_timestamp from both Time and String " do
    content_time = parse_time('1990-05-26 14:00:00', @config)

    ## document_time as Time
    doc = @doc.dup
    doc.content['timestamp'] = content_time
    assert_not_equal content_time, doc.document_timestamp, 'pre-condition'
    set_field_map_attrs(doc, @config)
    assert_equal content_time, doc.document_timestamp, 'set_field_map_attrs should set document_timestamp from Time'

    ## document_time as String
    doc = @doc.dup
    doc.content['timestamp'] = content_time.to_s
    assert_not_equal content_time, doc.document_timestamp, 'pre-condition'
    set_field_map_attrs(doc, @config)
    assert_equal content_time, doc.document_timestamp, 'set_field_map_attrs should set document_timestamp from Time'
  end

  test "set_field_map_attrs should set doc attrs from source/metadata when not set and not in content" do
    doc = @doc.dup
    doc.title              = nil
    doc.copyright          = nil
    doc.document_timestamp = nil
    doc.content            = {
      'nested' => @content,
    }

    set_field_map_attrs(doc, @config)

    assert_equal doc.source.filename,        doc.title
    assert_equal @doc.metadata['copyright'], doc.copyright
    assert_equal @doc.source.mtime,          doc.document_timestamp
  end

  test "set_field_map_attrs should set copyright when not set and not in content and metadata is an Array" do
    metadata_copyright = 'Array Metadata Copyright'
    metadata = [
      'some stuff',
      [
        'more stuff',
        {
          'hi'        => 'there',
          'copyright' => metadata_copyright,
          'there'     => 'hi',
        },
        'and more',
      ],
      {
        'key' => 'val',
      }
    ]

    ## cannot set doc.metadata to an Array, but you can create a new doc with metadata Array
    doc = Armagh::Documents::ActionDocument.new(
      document_id: 'doc document_id',
      title:       'doc title',
      copyright:   nil,
      content:     {},
      raw:         nil,
      metadata:    metadata,
      docspec:     nil,
      source:      @source,
      document_timestamp: @now
    )

    assert_not_equal metadata_copyright, doc.copyright, 'pre-condition'

    set_field_map_attrs(doc, @config)

    assert_equal metadata_copyright, doc.copyright
  end

  test "set_field_map_attrs should set doc attrs to default values when not set, not in content, and not in source/metadata" do
    doc = @doc.dup
    doc.title              = nil
    doc.copyright          = nil
    doc.document_timestamp = nil
    doc.content            = {
      'nested' => @content,
    }
    doc.metadata           = {
      'NOT-copyright' => 'NOT Copyright'
    }
    doc.source.filename = nil
    doc.source.mtime    = nil

    set_field_map_attrs(doc, @config)

    assert_nil doc.title
    assert_nil doc.copyright
    assert_nil doc.document_timestamp
  end

  test "set_field_map_attrs should set doc attrs to default values when not set, not in content, not in metadata, and doc.source is nil" do
    doc = Armagh::Documents::ActionDocument.new(
      document_id: 'doc document_id',
      title:       nil,
      copyright:   nil,
      content:     { 'nested' => @content },
      raw:         nil,
      metadata:    { 'NOT-copyright' => 'NOT Copyright' },
      docspec:     nil,
      source:      nil,
      document_timestamp: nil
    )

    set_field_map_attrs(doc, @config)

    assert_nil doc.title
    assert_nil doc.copyright
    assert_nil doc.document_timestamp
  end
end
