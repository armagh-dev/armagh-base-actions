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

require_relative '../../lib/armagh/documents/doc_type_state'

class TestDocTypeState < Test::Unit::TestCase

	def setup
    @type = 'doctype'
    @state = Armagh::DocState::WORKING
    @doc_type_state = Armagh::DocTypeState.new(@type, @state)
  end

  def test_init
    assert_equal(@state, @doc_type_state.state)
    assert_equal(@type, @doc_type_state.type)
  end

  def test_invalid_state
    assert_raise(Armagh::ActionErrors::StateError) do
      @doc_type_state = Armagh::DocTypeState.new(@type, 'invalid')
    end
  end

  def test_eq
    assert_true Armagh::DocTypeState.new('type', Armagh::DocState::PUBLISHED) == Armagh::DocTypeState.new('type', Armagh::DocState::PUBLISHED)
    assert_false Armagh::DocTypeState.new('type', Armagh::DocState::PUBLISHED) == Armagh::DocTypeState.new('type', Armagh::DocState::WORKING)
    assert_false Armagh::DocTypeState.new('type1', Armagh::DocState::PUBLISHED) == Armagh::DocTypeState.new('type2', Armagh::DocState::PUBLISHED)
  end

  def test_eql?
    assert_true Armagh::DocTypeState.new('type', Armagh::DocState::PUBLISHED).eql?(Armagh::DocTypeState.new('type', Armagh::DocState::PUBLISHED))
    assert_false Armagh::DocTypeState.new('type', Armagh::DocState::PUBLISHED).eql?(Armagh::DocTypeState.new('type', Armagh::DocState::WORKING))
    assert_false Armagh::DocTypeState.new('type1', Armagh::DocState::PUBLISHED).eql?(Armagh::DocTypeState.new('type2', Armagh::DocState::PUBLISHED))
  end

  def test_hash
    assert_equal Armagh::DocTypeState.new('type', Armagh::DocState::PUBLISHED).hash, Armagh::DocTypeState.new('type', Armagh::DocState::PUBLISHED).hash
    assert_not_equal Armagh::DocTypeState.new('type', Armagh::DocState::PUBLISHED).hash, Armagh::DocTypeState.new('type', Armagh::DocState::WORKING).hash
    assert_not_equal Armagh::DocTypeState.new('type1', Armagh::DocState::PUBLISHED).hash, Armagh::DocTypeState.new('type2', Armagh::DocState::PUBLISHED).hash
  end

  def test_to_s
    assert_equal 'type:published', Armagh::DocTypeState.new('type', Armagh::DocState::PUBLISHED).to_s
    assert_equal 'another:working', Armagh::DocTypeState.new('another', Armagh::DocState::WORKING).to_s
    assert_equal 'third:ready', Armagh::DocTypeState.new('third', Armagh::DocState::READY).to_s
  end

end
