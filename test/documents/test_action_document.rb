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

require_relative '../../lib/armagh/documents/action_document'
require_relative '../../lib/armagh/documents/doc_state'

class TestActionDocument < Test::Unit::TestCase

	def setup
    @id = '123'
    @draft_content = 'draft content'
    @published_content = 'published content'
    @meta = {'meta' => true}
    @docspec = Armagh::DocSpec.new('doctype', Armagh::DocState::PUBLISHED)
		@doc = Armagh::ActionDocument.new(@id, @draft_content, @published_content, @meta, @docspec)
  end

  def test_draft_content
    assert_equal(@draft_content, @doc.draft_content)
    new_content = {'new content' => false}
    @doc.draft_content = new_content
    assert_equal(new_content, @doc.draft_content)
  end

  def test_published_content
    assert_equal(@published_content, @doc.published_content)
    assert_raise {@doc.published_content = 'new content'}
    assert_raise {@doc.published_content << 'new content'}
    assert_equal(@published_content, @doc.published_content)
  end

  def test_meta
    assert_equal(@meta, @doc.meta)
    new_meta = {'new meta' => false}
    @doc.meta = new_meta
    assert_equal(new_meta, @doc.meta)
  end

  def test_docspec
    assert_equal(@docspec, @doc.docspec)
    new_docspec = Armagh::DocSpec.new('doctype2', Armagh::DocState::WORKING)
    @doc.docspec = new_docspec
    assert_equal(new_docspec, @doc.docspec)
  end

  def test_new_document?
    assert_false @doc.new_document?
    @doc = Armagh::ActionDocument.new(@id, @draft_content, @published_content, @meta, @docspec, true)
    assert_true @doc.new_document?
  end

end
