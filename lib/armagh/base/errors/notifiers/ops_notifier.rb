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
class OpsNotifier
  class ArgumentError < StandardError; end

  def notify(calling_action, error)
    raise ArgumentError.new("calling_action can't be nil") if calling_action.nil?

    action_name = calling_action.name
    logger      = calling_action.logger_name

    calling_action.caller.notify_ops(logger, action_name, error)
  end
end
