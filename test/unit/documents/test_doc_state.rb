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

require_relative '../../../lib/armagh/documents/doc_state'

class TestDocState < Test::Unit::TestCase

	def setup

  end

  def test_valid_state
    assert_true(Armagh::Documents::DocState.valid_state?(Armagh::Documents::DocState::WORKING))
    assert_true(Armagh::Documents::DocState.valid_state?(Armagh::Documents::DocState::READY))
    assert_true(Armagh::Documents::DocState.valid_state?(Armagh::Documents::DocState::PUBLISHED))
  end

  def test_invalid_state
    assert_false(Armagh::Documents::DocState.valid_state?(123))
    assert_false(Armagh::Documents::DocState.valid_state?('invalid state'))
  end

end
