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

require_relative '../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../lib/armagh/support/doc_attr'
require_relative '../../../lib/armagh/documents/action_document'

class TestDocAttr < Test::Unit::TestCase
  include Armagh::Support::DocAttr


  test "get_doc_attr should return proper value when sending in content" do
    content = { 'key' => 'Open Sesame' }

    assert_equal 'Open Sesame', get_doc_attr(content, ['key'])
  end

  test "get_doc_attr should return proper value when sending in doc" do
    content = { 'key' => 'Open Sesame' }
    doc     = Armagh::Documents::ActionDocument.new(
      document_id: nil,
      title:       nil,
      copyright:   nil,
      content:     content,
      raw:         nil,
      metadata:    nil,
      docspec:     nil,
      source:      nil,
      document_timestamp: nil,
    )

    assert_equal 'Open Sesame', get_doc_attr(doc, ['key'])
  end

  test "get_doc_attr should return nil when doc_or_content is nil" do
    assert_nil get_doc_attr(nil, ['key'])
  end

  test "get_doc_attr should return nil when doc.content is nil" do
    doc = Armagh::Documents::ActionDocument.new(
      document_id: nil,
      title:       nil,
      copyright:   nil,
      content:     nil,
      raw:         nil,
      metadata:    nil,
      docspec:     nil,
      source:      nil,
      document_timestamp: nil,
    )

    assert_nil get_doc_attr(doc, ['key'])
  end

  test "get_doc_attr should return nil when hpath is nil or empty" do
    assert_nil get_doc_attr({}, nil), 'get_doc_attr should return nil when hpath is nil'
    assert_nil get_doc_attr({}, [] ), 'get_doc_attr should return nil when hpath is empty'
  end

  test "get_doc_attr should return nil when hpath is not in content" do
    content = { 'UneedA' => 'lock smith', }

    assert_nil get_doc_attr(content, ['key'])
  end

  test "get_doc_attr should return nil when it finds a nil value" do
    content = { 'NilClass' => nil, }

    assert_nil get_doc_attr(content, ['NilClass'])
  end

  test "get_doc_attr should return proper Object" do
    content = {
      'String'        => 'string',
      'Padded String' => '    string    ',
      'int'           => 10,
      'float'         => 10.1,
      'TrueClass'     => true,
      'FalseClass'    => false,
      'Time'          => @now,
      'Hash'          => { 'key' => 'val' },
      'Array'         => [ 1, 2, 3 ],
      'Object'        => Object.new,
      'Regexp'        => /hi there/,
      'Doc'           => @doc,
    }

    content.each do |key, val|
      assert_equal val, get_doc_attr(content, [key])
    end
  end

  test "get_doc_attr should not convert String key to Symbol or Symbol key to String" do
    content = {
      'String' => 'val for String',
      :Symbol  => 'val for Symbol',
    }

    assert_equal content['String'], get_doc_attr(content, ['String']), "get_doc_attr should have found String key 'String' given ['String']"
    assert_equal content[:Symbol],  get_doc_attr(content, [:Symbol ]), "get_doc_attr should have found Symbol key :Symbol given [:Symbol]"

    assert_nil get_doc_attr(content, [:String ]), "get_doc_attr should not have found String key 'String' given [:String]"
    assert_nil get_doc_attr(content, ['Symbol']), "get_doc_attr should not have found Symbol key :Symbol given ['Symbol']"
  end

  test "get_doc_attr should find nested hpaths, including array elements" do
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
      assert_equal val, get_doc_attr(content, hpath), "get_doc_attr for #{hpath} should have returned #{val}"
    end

    expected_nil.each do |hpath|
      assert_nil get_doc_attr(content, hpath), "get_doc_attr for #{hpath} should have been nil"
    end
  end
end
