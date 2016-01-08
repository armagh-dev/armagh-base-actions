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

require 'test/unit'
require 'mocha/test_unit'

# DO NOT MODIFY THIS FILE

require_relative '../lib/armagh/client_actions'

class TestClientActions < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_name
    assert_not_empty(Armagh::ClientActions::NAME, 'No NAME defined for ClientActions')
  end

  def test_version
    assert_not_empty(Armagh::ClientActions::VERSION, 'No VERSION defined for ClientActions')
  end

  def test_available_actions
    assert_not_empty(Armagh::ClientActions.available_actions, 'No Available Actions were discovered')
  end
end