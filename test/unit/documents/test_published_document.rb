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
    @content = {'content' => true}
    @metadata = {'meta' => true}
    @document_timestamp = Time.now
    @docspec = Armagh::Documents::DocSpec.new('doctype', Armagh::Documents::DocState::PUBLISHED)
    @source = {'source' => 'something'}
    @title = 'title'
    @copyright = 'copyright'
		@doc = Armagh::Documents::PublishedDocument.new(document_id: @document_id, content: @content,
                                                 metadata: @metadata, docspec: @docspec, source: @source,
                                                 document_timestamp: @document_timestamp, title: @title, copyright: @copyright)
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
end
