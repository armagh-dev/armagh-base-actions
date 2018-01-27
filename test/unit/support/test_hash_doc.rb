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

require_relative '../../../lib/armagh/support/hash_doc'

class TestHashDoc < Test::Unit::TestCase

  def setup
    @hash = {
      'xml'=>{
        'book'=>{
          'title'=>'Moby Dick',
          'author'=>{
            'name'=>{
              'fname'=>'Herman',
              'mname'=>'',
              'lname'=>'Melville',
              'title'=>'Novelist'
            },
            'address'=>{
              'street'=>'37 American Dr',
              'apt'=>'',
              'city'=>'Fiction',
              'state'=>'AA',
              'zip'=>'00000'
            },
          },
          'year'=>'1851',
          'chapter'=>[
            {'attr_number'=>'01', 'text'=>'Loomings'},
            {'attr_number'=>'02', 'text'=>'The Carpet-Bag'},
            {'attr_number'=>'03', 'text'=>'The Spouter-Inn'}
          ]
        }
      },
      'empty_string'=>'',
      'empty_array'=>[],
      'number'=>1
    }
    @doc = Armagh::Support::HashDoc.new(@hash)
  end

  #
  # set
  #

  def test_set
    hash = {'test' => true}
    @doc.set(hash)
    assert_equal hash, @doc
  end

  def test_set_type_mismatch
    array = ['test']
    e = assert_raise Armagh::Support::HashDoc::TypeMismatchError do
      @doc.set(array)
    end
    assert_equal 'Hash object expected, instead: Array', e.message
  end

  #
  # get
  #

  def test_get
    assert_equal @hash['xml'], @doc.get('xml')
  end

  def test_get_as_symbol
    assert_equal @hash['xml'], @doc.get(:xml)
  end

  def test_get_dig
    assert_equal @hash.dig('xml', 'book', 'chapter', 1, 'text'), @doc.get('xml', 'book', 'chapter', 1, 'text')
  end

  def test_get_dot
    assert_equal @hash.dig('xml', 'book', 'chapter', 1, 'text'), @doc.get('xml.book.chapter.1.text')
  end

  def test_get_default
    expected = 'Ishmael'
    assert_equal expected, @doc.get('empty_string', default: expected)
  end

  def test_get_default_dot
   expected = 'Pip'
    assert_equal expected, @doc.get('xml.book.author.address.apt', default: expected)
  end

  def test_get_allow_missing
    assert_nil @doc.get('not there', allow_missing: true)
  end

  def test_get_allow_missing_dot
    assert_nil @doc.get('xml.book.not_there', allow_missing: true)
  end

  def test_get_default_allow_missing
    expected  = 'Ahab'
    assert_equal expected, @doc.get('not there', default: expected, allow_missing: true)
  end

  def test_get_default_allow_missing_dot
    expected = 'Starbuck'
    assert_equal expected, @doc.get('xml.book.not_there', default: expected, allow_missing: true)
  end

  def test_get_invalid_reference
    e = assert_raise Armagh::Support::HashDoc::InvalidReferenceError do
      @doc.get('not there').inspect
    end
    assert_equal '["not there"]', e.message
  end

  def test_get_invalid_reference_dot
    e = assert_raise Armagh::Support::HashDoc::InvalidReferenceError do
      @doc.get('xml.book.chapter.one.text')
    end
    assert_equal '["xml", "book", "chapter", "one", "text"]', e.message
  end

  def test_get_invalid_reference_string_allow_missing
    assert_nil @doc.get('empty_string', 'not there', allow_missing: true)
  end

  def test_get_invalid_reference_number_allow_missing
    assert_nil @doc.get('number', 'not there', allow_missing: true)
  end

  def test_get_allow_missing_class_attribute
    @doc.allow_missing = true
    assert_nil @doc.get('not there')
  end

  def test_get_from_empty_array_allow_missing
    assert_nil @doc.get('empty_array', 'not there', allow_missing: true)
  end

  def test_get_from_empty_array_invalid_reference
    e = assert_raise Armagh::Support::HashDoc::InvalidReferenceError do
      @doc.get('empty_array', 'not there')
    end
    assert_equal '["empty_array", "not there"]', e.message
  end

  #
  # with
  #

  def test_with
    @doc.with 'xml', 'book' do
      assert_equal @hash.dig('xml', 'book', 'title'), @doc.get('title')
    end
  end

  def test_with_dot
    @doc.with 'xml.book' do
      assert_equal @hash.dig('xml', 'book', 'title'), @doc.get('title')
    end
  end

  def test_with_nested
    @doc.with 'xml' do
      @doc.with 'book' do
        assert_equal @hash.dig('xml', 'book', 'title'), @doc.get('title')
      end
    end
  end

  def test_with_invalid_reference
    e = assert_raise Armagh::Support::HashDoc::InvalidReferenceError do
      @doc.with('not there') {}
    end
    assert_equal '["not there"]', e.message
  end

  def test_with_invalid_reference_allow_missing
    assert_nothing_raised do
      @doc.with('not there', allow_missing: true) {}
    end
  end

  def test_with_invalid_reference_allow_missing_class_attribute
    @doc.allow_missing = true
    assert_nothing_raised do
      @doc.with('not there') {}
    end
  end

  def test_with_no_block_given
    e = assert_raise LocalJumpError do
      @doc.with('xml')
    end
    assert_equal 'no block given (yield)', e.message
  end

  def test_with_nested_hierarchy_before_after
    @doc.with 'xml' do
      assert_equal @hash.dig('xml'), @doc.get
      @doc.with 'book' do
        assert_equal @hash.dig('xml', 'book'), @doc.get
        @doc.with 'chapter' do
          assert_equal @hash.dig('xml', 'book', 'chapter'), @doc.get
        end
        assert_equal @hash.dig('xml', 'book'), @doc.get
      end
      assert_equal @hash.dig('xml'), @doc.get
    end
  end

  def test_with_ref_gets_reset_after_error
    hash = {'root'=>{'key'=>'value'}}
    doc = Armagh::Support::HashDoc.new(hash)
    begin
      doc.with('root') { raise }
    rescue
    end
    assert_equal hash, doc.get
  end

  #
  # loop
  #

  def test_loop
    @doc.loop 'xml', 'book', 'chapter' do |i|
      assert_equal @hash.dig('xml', 'book', 'chapter', i - 1), @doc.get
    end
  end

  def test_loop_dot
    @doc.loop 'xml.book.chapter' do |i|
      assert_equal @hash.dig('xml', 'book', 'chapter', i - 1), @doc.get
    end
  end

  def test_loop_non_array
    @doc.loop 'xml', 'book', 'title' do
      assert_equal @hash.dig('xml', 'book', 'title'), @doc.get
    end
  end

  def test_loop_empty_array
    check = true
    @doc.loop 'empty_array' do
      check = @doc.get
    end
    assert_true check
  end

  def test_loop_empty_array_show_empty
    check = true
    @doc.loop 'empty_array', show_empty: true do
      check = @doc.get
    end
    assert_equal [], check
  end

  def test_loop_invalid_reference
    e = assert_raise Armagh::Support::HashDoc::InvalidReferenceError do
      @doc.loop('not there') {}
    end
    assert_equal '["not there"]', e.message
  end

  def test_loop_invalid_reference_allow_missing
    check = true
    @doc.loop 'not there', allow_missing: true do
      check = @doc.get
    end
    assert_true check
  end

  def test_loop_invalid_reference_allow_missing_class_attribute
    check = true
    @doc.allow_missing = true
    @doc.loop 'not there' do
      check @doc.get
    end
    assert_true check
  end

  def test_loop_no_block_given
    e = assert_raise LocalJumpError do
      @doc.loop('xml')
    end
    assert_equal 'no block given (yield)', e.message
  end

  def test_loop_ref_gets_reset_after_error
    hash = {'root'=>{'key'=>'value'}}
    doc = Armagh::Support::HashDoc.new(hash)
    begin
      doc.loop('root') { raise }
    rescue
    end
    assert_equal hash, doc.get
  end

  def test_loop_ref_gets_reset_after_error_in_empty
    hash = {'root'=>[]}
    doc = Armagh::Support::HashDoc.new(hash)
    begin
      doc.loop('root', show_empty: true) { raise }
    rescue
    end
    assert_equal hash, doc.get
  end

  #
  # enum
  #

  def test_enum
    hash = {'Moby Dick'=>'A novel by American writer Herman Melville.'}
    assert_equal [hash.keys.first, hash.values.first], @doc.enum('xml', 'book', 'title', hash)
  end

  def test_enum_dot
    hash = {'Moby Dick'=>'A giant, largely white bull sperm whale.'}
    assert_equal [hash.keys.first, hash.values.first], @doc.enum('xml.book.title', hash)
  end

  def test_enum_not_found
    hash = {'other'=>'text'}
    assert_equal [@hash.dig('xml', 'book', 'title'), nil], @doc.enum('xml', 'book', 'title', hash)
  end

  def test_enum_else_as_array
    hash = {nil=>['other']}
    assert_equal [@doc.dig('xml', 'book', 'chapter', 1, 'text'), hash[nil].first],
      @doc.enum('xml', 'book', 'chapter', 1, 'text', hash)
  end

  def test_enum_else_as_string
    hash = {nil=>'other'}
    assert_equal [@doc.dig('xml', 'book', 'chapter', 1, 'text'), hash[nil]],
      @doc.enum('xml', 'book', 'chapter', 1, 'text', hash)
  end

  def test_enum_else_pair
    hash = {nil=>['value', 'other']}
    assert_equal hash[nil], @doc.enum('xml', 'book', 'chapter', 1, 'text', hash)
  end

  def test_enum_default
    hash = {'default'=>'Default'}
    assert_equal ['default', 'Default'], @doc.enum('empty_string', hash, default: 'default')
  end

  def test_enum_default_else
    hash = {nil=>'Other'}
    assert_equal ['default', 'Other'], @doc.enum('empty_string', hash, default: 'default')
  end

  def test_enum_invalid_hash_error
    e = assert_raise Armagh::Support::HashDoc::InvalidEnumHashDocError do
      @doc.enum('xml', 'book', 'chapter', 1, 'text', {})
    end
    assert_equal %q(Please provide a valid enum hash lookup, e.g., {'value'=>'description', nil=>['else', 'lookup not found']}), e.message
  end

  def test_enum_invalid_reference
    e = assert_raise Armagh::Support::HashDoc::InvalidReferenceError do
      @doc.enum('not there', {'value'=>'lookup'})
    end
    assert_equal '["not there"]', e.message
  end

  def test_enum_allow_missing
    assert_equal [nil, nil], @doc.enum('not there', {'value'=>'lookup'}, allow_missing: true)
  end

  def test_enum_allow_missing_class_attribute
    @doc.allow_missing = true
    assert_equal [nil, nil], @doc.enum('not there', {'value'=>'lookup'})
  end

  def test_enum_format
    assert_equal '1851 | Eighteen fifty one',
      @doc.enum('xml', 'book', 'year', {'1851'=>'Eighteen fifty one'}, format: '%s | %s')
  end

  def test_enum_format_number
    assert_equal '1 | One', @doc.enum('number', {1=>'One'}, format: '%s | %s')
  end

  def test_enum_format_class_attribute
    @doc.enum_format = '%s'
    assert_equal 'nothing', @doc.enum('empty_string', {''=>'nothing'})
  end

  def test_enum_format_not_in_hash
    assert_equal '1', @doc.enum('number', {}, format: '%s | %s')
  end

  #
  # concat
  #

  def test_concat
    @doc.with 'xml', 'book' do
      assert_equal 'Moby Dick -- 1851, Herman Melville',
        @doc.concat('@title -- @year, @author.name.fname @author.name.lname')
    end
  end

  def test_concat_dot
    assert_equal 'Moby Dick, The Spouter-Inn', @doc.concat('@xml.book.title, @xml.book.chapter.2.text')
  end

  def test_concat_allow_missing
    assert_equal '', @doc.concat('@not_there', allow_missing: true)
  end

  def test_concat_allow_missing_class_attribute
    @doc.allow_missing = true
    assert_equal '', @doc.concat('@not_there')
  end

  def test_concat_empty_first_field
    assert_equal '1; 1', @doc.concat('@not_there, @number; @number', allow_missing: true)
  end

  def test_concat_empty_middle_field
    assert_equal '1, 1', @doc.concat('@number, @not_there; @number', allow_missing: true)
  end

  def test_concat_empty_last_field
    assert_equal '1, 1', @doc.concat('@number, @number; @not_there', allow_missing: true)
  end

  def test_concat_empty_first_last_field
    assert_equal '1', @doc.concat('@not_there, @number; @not_there', allow_missing: true)
  end

  def test_concat_prefix
    assert_equal '<1', @doc.concat('<@number')
  end

  def test_concat_suffix
    assert_equal '1>', @doc.concat('@number>')
  end

  def test_concat_prefix_suffix_empty_field
    assert_equal '', @doc.concat('<@not_there>', allow_missing: true)
  end

  def test_concat_prefix_suffix
    assert_equal '<1, 1; 1>', @doc.concat('<@number, @number; @number>')
  end

  def test_concat_prefix_first_empty_field
    assert_equal '<1; 1', @doc.concat('<@not_there, @number; @number', allow_missing: true)
  end

  def test_concat_suffix_last_empty_field
    assert_equal '1, 1>', @doc.concat('@number, @number; @not_there>', allow_missing: true)
  end

  def test_concat_prefix_suffix_empty_fields
    assert_equal '', @doc.concat('<@not_there, @not_there; @not_there>', allow_missing: true)
  end

  def test_concat_address
    @doc.with('xml', 'book', 'author', 'address') do
      assert_equal '37 American Dr, Fiction, AA  00000', @doc.concat('@street, @apt, @city, @state  @zip')
    end
  end

  def test_concat_prefix_suffix_dig
    assert_equal '<Moby Dick: Melville>', @doc.concat('<@xml.book.title: @xml.book.author.name.lname>')
  end

  def test_concat_invalid_reference
    e = assert_raise Armagh::Support::HashDoc::InvalidReferenceError do
      @doc.concat('@not_there')
    end
    assert_equal '["not_there"]', e.message
  end

  def test_concat_invalid_layout
    e = assert_raise Armagh::Support::HashDoc::InvalidConcatLayoutError do
      @doc.concat({a: 1, b: 2})
    end
    assert_equal 'Must be String, instead: Hash', e.message
  end

  #
  # find_all
  #

  def test_find_all_text_nodes
    expected = [] <<
      @hash.dig('xml', 'book', 'chapter', 0, 'text') <<
      @hash.dig('xml', 'book', 'chapter', 1, 'text') <<
      @hash.dig('xml', 'book', 'chapter', 2, 'text')
    assert_equal expected, @doc.find_all('text')
  end

  def test_find_all_no_hits
    assert_equal [], @doc.find_all('not there')
  end

  def test_find_all_source_not_hash
    assert_equal [], @doc.find_all('array', 'just a string')
  end

  #
  # audit
  #

  def test_audit_no_block_given
    e = assert_raise LocalJumpError do
      @doc.audit
    end
    assert_equal 'no block given (yield)', e.message
  end

  def test_audit
    result = @doc.audit do
      @doc.get 'xml', 'book', 'author', 'name', 'lname'
      @doc.get 'xml', 'book', 'chapter', 1, 'text'
      @doc.get 'xml', 'book', 'chapter', 2, 'text'
    end
    expected = {
      0=>["apt", "attr_number", "city", "empty_string", "fname", "mname", "number", "state", "street", "title", "year", "zip"],
      1=>["lname"],
      2=>["text"]
    }
    assert_equal expected, result
  end

end
