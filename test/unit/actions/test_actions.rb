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
require 'mocha/test_unit'

require_relative '../../../lib/armagh/actions'

module Armagh
  module StandardActions
    
    class ThisTestCollect < Actions::Collect; end
    class ThisTestPublish < Actions::Publish; end
  end
  
  module CustomActions
    
    class ThatTestSplit < Actions::Split; end
  end
end

class TestActions < Test::Unit::TestCase

  def test_defined_actions
    
    defined_classes = [
      Armagh::StandardActions::ThisTestCollect,
      Armagh::StandardActions::ThisTestPublish,
      Armagh::CustomActions::ThatTestSplit
    ]
    
    assert_equal defined_classes, Armagh::Actions.defined_actions
  end
end