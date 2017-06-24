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
require_relative '../../../lib/armagh/actions/abortable'

require 'test/unit'
require 'mocha/test_unit'

class Armagh::Actions::AbortableItem
  include Armagh::Actions::Abortable

  def initialize(name, caller)
    @name = name
    @caller = caller
  end
end

class TestAbortable < Test::Unit::TestCase
  def setup
    @caller = mock('caller')
    @name = 'test_object'
    @loggable = Armagh::Actions::AbortableItem.new(@name, @caller)
  end

  def test_abort
    @caller.expects(:abort)
    @loggable.abort
  end
end
