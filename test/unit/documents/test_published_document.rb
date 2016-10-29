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

require_relative '../../../lib/armagh/documents/published_document'
require_relative '../../../lib/armagh/documents/doc_spec'
require_relative '../../../lib/armagh/documents/doc_state'

class TestPublishedDocument < Test::Unit::TestCase

	def setup
    @document_id = '123'
    @bson_binary = 'something'
    @text_content = 'text content'
    @content = {'content' => true, 'bson_binary' => BSON::Binary.new(@bson_binary), 'text_content' => @text_content}
    @metadata = {'meta' => true}
    @document_timestamp = Time.now
    @docspec = Armagh::Documents::DocSpec.new('doctype', Armagh::Documents::DocState::PUBLISHED)
    @source = {'source' => 'something'}
    @title = 'title'
    @copyright = 'copyright'
    @display = 'display'
		@doc = Armagh::Documents::PublishedDocument.new(document_id: @document_id,
                                                    content: @content,
                                                    metadata: @metadata,
                                                    docspec: @docspec,
                                                    source: @source,
                                                    document_timestamp: @document_timestamp,
                                                    title: @title,
                                                    copyright: @copyright,
                                                    display: @display)
  end

  def test_type
    assert_kind_of(Armagh::Documents::ActionDocument, @doc)
  end

  def test_source
    assert_equal(@source, @doc.source)
    assert_not_same(@source, @doc.source)
    assert_raise(Armagh::Documents::Errors::DocumentError){@doc.source = @source}
  end

  def test_content
    assert_equal(@content, @doc.content)
    assert_not_same(@content, @doc.content)
    assert_raise(Armagh::Documents::Errors::DocumentError){@doc.content = @content}
    assert_raise{@doc.content['something'] = 'new'}
  end

  def test_document_id
    assert_equal(@document_id, @doc.document_id)
    assert_not_same(@document_id, @doc.document_id)
    assert_raise(Armagh::Documents::Errors::DocumentError){@doc.document_id = @document_id}
  end

  def test_title
    assert_equal(@title, @doc.title)
    assert_not_same(@title, @doc.title)
    assert_raise(Armagh::Documents::Errors::DocumentError){@doc.title = @title}
  end

  def test_copyright
    assert_equal(@copyright, @doc.copyright)
    assert_not_same(@copyright, @doc.copyright)
    assert_raise(Armagh::Documents::Errors::DocumentError){@doc.copyright = @copyright}
  end

  def test_docspec
    assert_equal(@docspec, @doc.docspec)
    assert_raise(Armagh::Documents::Errors::DocumentError){@doc.docspec = @docspec}
  end

  def test_document_timestamp
    assert_equal(@document_timestamp, @doc.document_timestamp)
    assert_raise(Armagh::Documents::Errors::DocumentError){@doc.document_timestamp = @document_timestamp}
  end

  def test_display
    assert_equal(@display, @doc.display)
    assert_not_same(@display, @doc.display)
    assert_raise(Armagh::Documents::Errors::DocumentError){@doc.display = @display}
  end

  def test_raw
    assert_equal(@bson_binary, @doc.raw)
    assert_not_same(@bson_binary, @doc.raw)
    assert_raise(Armagh::Documents::Errors::DocumentError){@doc.raw = 'something'}
  end

  def test_text
    assert_equal(@text_content, @doc.text)
    assert_not_same(@text_content, @doc.text)
    assert_raise{@doc.text << 'howdy'}
    assert_raise(Armagh::Documents::Errors::DocumentError){@doc.text = 'something'}
  end

  def test_hash
    assert_equal(@doc.content, @doc.hash)
    assert_not_same(@doc.content, @doc.hash)

    assert_raise(Armagh::Documents::Errors::DocumentError){@doc.hash = {}}
    assert_raise{@doc.hash['something'] = 'wrong'}
  end

  def test_nils
    doc = Armagh::Documents::PublishedDocument.new(document_id: @document_id,
                                                  content: @content,
                                                  metadata: @metadata,
                                                  docspec: @docspec,
                                                  source: @source)
    assert_nil doc.title
    assert_nil doc.copyright
    assert_nil doc.document_timestamp
    assert_nil doc.display
  end
end
