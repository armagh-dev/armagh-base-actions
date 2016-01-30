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

require_relative 'coverage_helper'

require 'test/unit'

require_relative '../lib/armagh/action_document'
require_relative '../lib/armagh/doc_state'

class TestActionDocument < Test::Unit::TestCase

	def setup
    @content = 'content'
    @meta = {'meta' => true}
    @state = Armagh::DocState::PUBLISHED
		@doc = Armagh::ActionDocument.new(@content, @meta, @state)
  end

  def test_content
    assert_equal(@content, @doc.content)
    new_content = 'new content'
    @doc.content = new_content
    assert_equal(new_content, @doc.content)
  end

  def test_meta
    assert_equal(@meta, @doc.meta)
    new_meta = {'new meta' => false}
    @doc.meta = new_meta
    assert_equal(new_meta, @doc.meta)
  end

  def test_state
    assert_equal(@state, @doc.state)
    new_state = Armagh::DocState::CLOSED
    @doc.state = new_state
    assert_equal(new_state, @doc.state)
  end

end
