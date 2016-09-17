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


require_relative '../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../lib/armagh/support/cron'

class TestCron < Test::Unit::TestCase
  def test_valid_cron
    assert_true Armagh::Support::Cron.valid_cron?('* * * * *')
    assert_true Armagh::Support::Cron.valid_cron?('*/10 */10 * * *')
    assert_true Armagh::Support::Cron.valid_cron?('@hourly')
  end

  def test_invalid_cron
    assert_false Armagh::Support::Cron.valid_cron?('invalid')
    assert_false Armagh::Support::Cron.valid_cron?('* * * *')
  end

  def test_next_execution_time
    time = Time.new(2007,11,1,15,25,0)
    next_time = Time.new(2007,11,1,15,26,0)
    assert_equal(next_time, Armagh::Support::Cron.next_execution_time('* * * * *', time))
  end

  def test_next_execution_time_invalid
    time = Time.new(2007,11,1,15,25,0)
    assert_raise(Armagh::Support::Cron::CronError){Armagh::Support::Cron.next_execution_time('invalid', time)}
  end
end
