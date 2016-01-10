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

require_relative '../lib/armagh/client_actions/example_action'

class ExampleActionTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @caller = mock
    @logger = mock
    config = {}
    @example_action = Armagh::ClientActions::ExampleAction.new(@caller, @logger, config)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.
  def teardown
    # Do nothing
  end

  def test_validate
    fail 'test_validate not implemented'
    #@example_action.validate
  end

  def test_execute
    fail 'test_execute not implemented'
    #@caller.expects(:insert_document).with(id, acted_content, acted_meta)
    #@example_action.execute('content', {})
  end
end