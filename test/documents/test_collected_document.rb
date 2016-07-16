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

require_relative '../../lib/armagh/documents/collected_document'
require_relative '../../lib/armagh/documents/doc_spec'

class TestCollectedDocument < Test::Unit::TestCase

	def setup
    @collected_file = 'content'
    @metadata = {'metadata' => true}
    @docspec = Armagh::Documents::DocSpec.new('doctype', Armagh::Documents::DocState::PUBLISHED)
		@doc = Armagh::Documents::CollectedDocument.new(collected_file: @collected_file, metadata: @metadata, docspec: @docspec)
  end

  def test_unable_to_modify_collected_file
    assert_raise {@doc.document_id = 'something'}
    assert_raise {@doc.document_id << 'wee'}
  end

  def test_metadata
    assert_true @doc.metadata['metadata']
    @doc.metadata['metadata'] = false
    assert_false @doc.metadata['metadata']
  end

  def test_unable_to_modify_docspec
    assert_raise {@doc.docspec = Armagh::Documents::DocSpec.new('another', Armagh::Documents::DocState::PUBLISHED)}
  end

end
