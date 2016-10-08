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
require 'json'

require_relative '../../../lib/armagh/documents/action_document'
require_relative '../../../lib/armagh/documents/doc_spec'
require_relative '../../../lib/armagh/documents/doc_state'

class TestActionDocument < Test::Unit::TestCase

	def setup
    @document_id = '123'
    @content = {'content' => true}
    @metadata = {'meta' => true}
    @document_timestamp = Time.now
    @docspec = Armagh::Documents::DocSpec.new('doctype', Armagh::Documents::DocState::PUBLISHED)
    @source = {'source' => 'something'}
    @title = 'title'
    @copyright = 'copyright'
    @display = 'display'
    @archive_file = 'archive file'
		@doc = Armagh::Documents::ActionDocument.new(document_id: @document_id,
                                                 content: @content,
                                                 metadata: @metadata,
                                                 docspec: @docspec,
                                                 source: @source,
                                                 document_timestamp: @document_timestamp,
                                                 title: @title,
                                                 copyright: @copyright,
                                                 display: @display,
                                                 archive_file: @archive_file,)
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

  def test_display
    assert_equal(@display, @doc.display)
    new_display = 'something new'
    @doc.display = new_display
    assert_equal(new_display, @doc.display)
    assert_raise(TypeError){@doc.document_timestamp = 123}
  end

  def test_archive_file
    assert_equal(@archive_file, @doc.archive_file)
  end

  def test_source
    assert_equal(@source, @doc.source)
    assert_raise(NoMethodError){@doc.source={}}
  end

  def test_new_document?
    assert_false @doc.new_document?
    @doc = Armagh::Documents::ActionDocument.new(document_id: @document_id, content: @content, metadata: @metadata,
                                      docspec: @docspec, source: @source, new: true)
    assert_true @doc.new_document?
  end

  def test_text
    text = 'some text'
    assert_nil @doc.text
    assert_not_empty @doc.content
    @doc.text = text
    assert_equal({'text_content' => 'some text'}, @doc.content)
    assert_equal(text, @doc.text)
  end

  def test_raw
    raw = 'some raw data'
    assert_nil @doc.raw
    assert_not_empty @doc.content
    @doc.raw = raw
    assert_equal({'bson_binary' => BSON::Binary.new(raw)}, @doc.content)
    assert_equal(raw, @doc.raw)
  end

  def test_hash
    assert_equal(@doc.content, @doc.hash)

    assert_nil @doc.hash['hash_key']
    @doc.content['hash_key'] = 'hash'
    assert_equal('hash', @doc.content['hash_key'])

    assert_nil @doc.content['content_key']
    @doc.content['content_key'] = 'content'
    assert_equal('content', @doc.hash['content_key'])

    hash = {'something' => 'else'}
    @doc.hash = hash
    assert_equal(hash, @doc.hash)
  end

  def test_to_json
    expected = {
        'document_id' => @doc.document_id,
        'title' => @doc.title,
        'copyright' => @doc.copyright,
        'metadata' => @doc.metadata,
        'content' => @doc.content,
        'source' => @doc.source,
        'document_timestamp' => @doc.document_timestamp,
        'docspec' => @doc.docspec.to_hash,
        'display' => @doc.display,
        'archive_file' => @doc.archive_file
    }.to_json
    assert_equal(expected, @doc.to_json)
  end
end
