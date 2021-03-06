# Copyright 2018 Noragh Analytics, Inc.
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
require 'mocha/test_unit'

require_relative '../../../lib/armagh/support/random'

class TestRandom < Test::Unit::TestCase

  def test_random_str
    rdm = Armagh::Support::Random.random_str(30)
    assert_equal 30, rdm.length

    rdm = Armagh::Support::Random.random_str(12)
    assert_equal 12, rdm.length
    assert_not_equal(Armagh::Support::Random.random_str(20), Armagh::Support::Random.random_str(20))
  end

  def test_random_id
    id = Armagh::Support::Random.random_id
    assert_equal id.length, Armagh::Support::Random::RANDOM_ID_LENGTH
    assert_not_equal(Armagh::Support::Random.random_id, Armagh::Support::Random.random_id)
  end

end
