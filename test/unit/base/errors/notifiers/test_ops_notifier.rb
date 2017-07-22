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

require_relative '../../../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../../../lib/armagh/base/errors/notifiers/ops_notifier'

class TestOpsNotifier < Test::Unit::TestCase

  test "#notify notifies ops" do
    caller_instance = stub('caller_instance', notify_ops: true)
    calling_action  = stub('calling_action', name: "some action", logger_name: "some_logger", caller: caller_instance)
    error           = stub('some_exception', message: 'something went wrong')
    caller_instance.expects(:notify_ops)

    notifier = OpsNotifier.new
    notifier.notify(calling_action, error)
  end

end
