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
require 'json'

require_relative '../../../lib/armagh/documents/action_document'
require_relative '../../../lib/armagh/documents/doc_spec'
require_relative '../../../lib/armagh/documents/doc_state'

class TestActionDocument < Test::Unit::TestCase

  def setup
    @document_id = '123'
    @content = {'content' => true}
    @raw = 'raw data'
    @metadata = {'meta' => true}
    @document_timestamp = Time.now.utc
    @docspec = Armagh::Documents::DocSpec.new('doctype', Armagh::Documents::DocState::PUBLISHED)
    @source = Armagh::Documents::Source.new(filename: 'test_file')
    @title = 'title'
    @copyright = 'copyright'
    @display = 'display'
    @version = 1
    @doc = Armagh::Documents::ActionDocument.new(document_id: @document_id,
                                                 content: @content,
                                                 raw: @raw,
                                                 metadata: @metadata,
                                                 docspec: @docspec,
                                                 source: @source,
                                                 document_timestamp: @document_timestamp,
                                                 title: @title,
                                                 copyright: @copyright,
                                                 display: @display,
                                                 version: @version
    )
  end

  def test_document_id
    assert_equal(@document_id, @doc.document_id)
    new = 'new'
    @doc.document_id = new
    assert_equal(new, @doc.document_id)
    assert_raise(TypeError){@doc.document_id = {}}
  end

  def test_metadata
    assert_equal(@metadata, @doc.metadata)
    new_meta = {'new meta' => false}
    @doc.metadata = new_meta
    assert_equal(new_meta, @doc.metadata)
    assert_raise(TypeError){@doc.metadata = 'meta'}
  end

  def test_content
    assert_equal(@content, @doc.content)
    new_content = {'new content' => false}
    @doc.content = new_content
    assert_equal(new_content, @doc.content)
    assert_raise(TypeError){@doc.content = 'meta'}
  end

  def test_raw_data
    assert_equal(@raw, @doc.raw)
    new_raw_data = 'new raw data'
    @doc.raw = new_raw_data
    assert_equal(new_raw_data, @doc.raw)
    assert_raise(TypeError){@doc.raw = {}}
  end

  def test_title
    assert_equal(@title, @doc.title)
    new = 'new'
    @doc.title = new
    assert_equal(new, @doc.title)
    assert_raise(TypeError){@doc.title = {}}
  end

  def test_copyright
    assert_equal(@copyright, @doc.copyright)
    new = 'new'
    @doc.copyright = new
    assert_equal(new, @doc.copyright)
    assert_raise(TypeError){@doc.copyright = {}}

    @doc.copyright = nil
    assert_equal(nil, @doc.copyright)
  end

  def test_docspec
    assert_equal(@docspec, @doc.docspec)
    new_docspec = Armagh::Documents::DocSpec.new('doctype2', Armagh::Documents::DocState::WORKING)
    @doc.docspec = new_docspec
    assert_equal(new_docspec, @doc.docspec)
    assert_raise(TypeError){@doc.docspec = {}}
  end

  def test_document_timestamp
    assert_equal(@document_timestamp, @doc.document_timestamp)
    new_timestamp = Time.now
    @doc.document_timestamp = new_timestamp
    assert_equal(new_timestamp, @doc.document_timestamp)
    assert_raise(TypeError){@doc.document_timestamp = {}}
  end

  def test_version
    assert_equal(@version, @doc.version)
    new_version = 123
    @doc.version = new_version
    assert_equal(new_version, @doc.version)
    assert_raise(TypeError){@doc.version = {}}
    assert_raise(TypeError){@doc.version = 1.0}
    assert_raise(TypeError){@doc.version = -2}
  end

  def test_display
    assert_equal(@display, @doc.display)
    new_display = 'something new'
    @doc.display = new_display
    assert_equal(new_display, @doc.display)
    assert_raise(TypeError){@doc.document_timestamp = 123}
  end

  def test_source
    assert_equal(@source, @doc.source)
    assert_raise(NoMethodError){@doc.source={}}
  end

  def test_new_document?
    assert_false @doc.new_document?
    @doc = Armagh::Documents::ActionDocument.new(document_id: @document_id,
                                                 content: @content,
                                                 raw: @raw,
                                                 metadata: @metadata,
                                                 docspec: @docspec,
                                                 source: @source,
                                                 new: true,
                                                 title: @title,
                                                 copyright: @copyright,
                                                 version: @version,
                                                 document_timestamp: @document_timestamp)
    assert_true @doc.new_document?
  end

  def test_text
    text = 'some text'
    assert_nil @doc.text
    assert_not_empty @doc.content
    @doc.text = text
    assert_equal({'text_content' => 'some text'}, @doc.content)
    assert_equal(text, @doc.text)

    @doc.instance_variable_set(:@content, nil)
    @doc.text = text
    assert_equal(text, @doc.text)
  end

  def test_raw
    raw = 'some raw data'
    assert_equal('raw data', @doc.raw)
    assert_equal({'content' => true}, @doc.content)
    @doc.raw = raw
    assert_equal(raw, @doc.raw)
    assert_equal({'content' => true}, @doc.content) # prior to ARM-549, setting raw cleared content

    @doc.instance_variable_set(:@content, nil)
    @doc.raw = raw
    assert_equal(raw, @doc.raw)
  end

  def test_raw_bson
    string = 'some data'
    raw = BSON::Binary.new(string)
    @doc.raw = raw
    assert_equal string, @doc.raw
  end

  def test_raw_nil
    @doc.raw = nil
    assert_nil @doc.raw
  end

  def test_raw_too_large
    bson_padding = BSON::Binary.new('').to_bson.length

    raw = 'a' * (Armagh::Documents::ActionDocument::RAW_MAX_LENGTH - bson_padding)
    assert_nothing_raised{@doc.raw = raw}

    raw = 'a' * (Armagh::Documents::ActionDocument::RAW_MAX_LENGTH - bson_padding + 1)
    assert_raise(Armagh::Documents::Errors::DocumentRawSizeError){@doc.raw = raw}

    raw = nil
    assert_nothing_raised{@doc.raw = raw}
  end

  def test_raw_invalid_argument
    raw = {}
    assert_equal('raw data', @doc.raw)
    assert_not_empty @doc.content

    assert_raise(TypeError){
      @doc.raw = raw
    }
  end

  def test_to_json
    expected = {
        'document_id' => @doc.document_id,
        'title' => @doc.title,
        'copyright' => @doc.copyright,
        'metadata' => @doc.metadata,
        'content' => @doc.content,
        'source' => @doc.source.to_hash,
        'document_timestamp' => @doc.document_timestamp,
        'docspec' => @doc.docspec.to_hash,
        'display' => @doc.display,
    }.to_json
    assert_equal(expected, @doc.to_json)
  end

  def test_from_hash
    hash = {
      'document_id' => @doc.document_id,
      'title' => @doc.title,
      'copyright' => @doc.copyright,
      'metadata' => @doc.metadata,
      'content' => @doc.content,
      'source' => @doc.source.to_hash,
      'document_timestamp' => @doc.document_timestamp,
      'docspec' => @doc.docspec.to_hash,
      'display' => @doc.display,
    }

    doc = Armagh::Documents::ActionDocument.from_hash(hash)
    assert_equal @doc.document_id, doc.document_id
    assert_equal @doc.title, doc.title
    assert_equal @doc.copyright, doc.copyright
    assert_equal @doc.metadata, doc.metadata
    assert_equal @doc.content, doc.content
    assert_equal @doc.source, doc.source
    assert_in_delta @doc.document_timestamp, doc.document_timestamp, 1
    assert_equal @doc.docspec, doc.docspec
    assert_equal @doc.display, doc.display
  end

  def test_from_hash_invalid
    hash = {
      'document_id' => @doc.document_id,
      'title' => @doc.title,
      'copyright' => @doc.copyright,
      'metadata' => 123,
      'content' => @doc.content,
      'source' => @doc.source.to_hash,
      'document_timestamp' => @doc.document_timestamp,
      'docspec' => @doc.docspec.to_hash,
      'display' => @doc.display,
    }

    assert_raise(TypeError){Armagh::Documents::ActionDocument.from_hash(hash)}
  end

  def test_hash_round_trip
    doc = Armagh::Documents::ActionDocument.from_hash(@doc.to_hash)
    assert_equal @doc.document_id, doc.document_id
    assert_equal @doc.title, doc.title
    assert_equal @doc.copyright, doc.copyright
    assert_equal @doc.metadata, doc.metadata
    assert_equal @doc.content, doc.content
    assert_equal @doc.source, doc.source
    assert_in_delta @doc.document_timestamp, doc.document_timestamp, 1
    assert_equal @doc.docspec, doc.docspec
    assert_equal @doc.display, doc.display
  end

  def test_from_json
    json = {
      'document_id' => @doc.document_id,
      'title' => @doc.title,
      'copyright' => @doc.copyright,
      'metadata' => @doc.metadata,
      'content' => @doc.content,
      'source' => @doc.source.to_hash,
      'document_timestamp' => @doc.document_timestamp,
      'docspec' => @doc.docspec.to_hash,
      'display' => @doc.display,
      'version' => @doc.version
    }.to_json

    doc = Armagh::Documents::ActionDocument.from_json(json)
    assert_equal @doc.document_id, doc.document_id
    assert_equal @doc.title, doc.title
    assert_equal @doc.copyright, doc.copyright
    assert_equal @doc.metadata, doc.metadata
    assert_equal @doc.content, doc.content
    assert_equal @doc.source, doc.source
    assert_in_delta @doc.document_timestamp, doc.document_timestamp, 1 # to_s loses the fraction of a second
    assert_equal @doc.docspec, doc.docspec
    assert_equal @doc.display, doc.display
    assert_equal @doc.version, doc.version
  end

  def test_from_json_invalid
    json = {
      'document_id' => @doc.document_id,
      'title' => @doc.title,
      'copyright' => @doc.copyright,
      'metadata' => @doc.metadata,
      'content' => @doc.content,
      'source' => @doc.source.to_hash,
      'document_timestamp' => @doc.document_timestamp,
      'docspec' => @doc.docspec.to_hash,
      'display' => @doc.display,
      'version' => 'invalid'
    }.to_json

    assert_raise(TypeError){Armagh::Documents::ActionDocument.from_json(json)}
  end

  def test_json_round_trip
    doc = Armagh::Documents::ActionDocument.from_json(@doc.to_json)
    assert_equal @doc.document_id, doc.document_id
    assert_equal @doc.title, doc.title
    assert_equal @doc.copyright, doc.copyright
    assert_equal @doc.metadata, doc.metadata
    assert_equal @doc.content, doc.content
    assert_equal @doc.source, doc.source
    assert_in_delta @doc.document_timestamp, doc.document_timestamp, 1
    assert_equal @doc.docspec, doc.docspec
    assert_equal @doc.display, doc.display
  end
end
