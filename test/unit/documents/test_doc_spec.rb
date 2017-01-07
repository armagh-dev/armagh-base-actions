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

require_relative '../../../lib/armagh/documents/doc_spec'
require 'configh'

class TestDocSpec < Test::Unit::TestCase

	def setup
    @type = 'doctype'
    @state = Armagh::Documents::DocState::WORKING
    @docspec = Armagh::Documents::DocSpec.new(@type, @state)
  end

  def test_init
    assert_equal(@state, @docspec.state)
    assert_equal(@type, @docspec.type)
  end

  def test_invalid_state
    assert_raise(Armagh::Documents::Errors::DocStateError) do
      @docspec = Armagh::Documents::DocSpec.new(@type, 'invalid')
    end
  end

  def test_invalid_type
    assert_raise(Armagh::Documents::Errors::DocSpecError) do
      @docspec = Armagh::Documents::DocSpec.new('', @state)
    end

    assert_raise(Armagh::Documents::Errors::DocSpecError) do
      @docspec = Armagh::Documents::DocSpec.new(123, @state)
    end
  end

  def test_eq
    assert_true Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::PUBLISHED) == Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::PUBLISHED)
    assert_false Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::PUBLISHED) == Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::WORKING)
    assert_false Armagh::Documents::DocSpec.new('type1', Armagh::Documents::DocState::PUBLISHED) == Armagh::Documents::DocSpec.new('type2', Armagh::Documents::DocState::PUBLISHED)
  end

  def test_eql?
    assert_true Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::PUBLISHED).eql?(Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::PUBLISHED))
    assert_false Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::PUBLISHED).eql?(Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::WORKING))
    assert_false Armagh::Documents::DocSpec.new('type1', Armagh::Documents::DocState::PUBLISHED).eql?(Armagh::Documents::DocSpec.new('type2', Armagh::Documents::DocState::PUBLISHED))
  end

  def test_hash
    assert_equal Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::PUBLISHED).hash, Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::PUBLISHED).hash
    assert_not_equal Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::PUBLISHED).hash, Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::WORKING).hash
    assert_not_equal Armagh::Documents::DocSpec.new('type1', Armagh::Documents::DocState::PUBLISHED).hash, Armagh::Documents::DocSpec.new('type2', Armagh::Documents::DocState::PUBLISHED).hash
  end

  def test_to_s
    assert_equal 'type:published', Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::PUBLISHED).to_s
    assert_equal 'another:working', Armagh::Documents::DocSpec.new('another', Armagh::Documents::DocState::WORKING).to_s
    assert_equal 'third:ready', Armagh::Documents::DocSpec.new('third', Armagh::Documents::DocState::READY).to_s
  end

  def test_to_hash
    assert_equal({'type' => 'type', 'state' => 'published'}, Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::PUBLISHED).to_hash)
    assert_equal({'type' => 'another', 'state' => 'working'}, Armagh::Documents::DocSpec.new('another', Armagh::Documents::DocState::WORKING).to_hash)
    assert_equal({'type' => 'third', 'state' => 'ready'}, Armagh::Documents::DocSpec.new('third', Armagh::Documents::DocState::READY).to_hash)
  end
  
  def test_datatype_ensure
    assert_equal Armagh::Documents::DocSpec.new( 'test', Armagh::Documents::DocState::READY ), Configh::DataTypes.ensure_value_is_datatype( 'test:ready', 'docspec' )
    e = assert_raises( Configh::DataTypes::TypeError ) do
      Configh::DataTypes.ensure_value_is_datatype( 'badstring', 'docspec' ).inspect
    end
    assert_equal 'value badstring cannot be cast as a docspec', e.message
  end
    

end
