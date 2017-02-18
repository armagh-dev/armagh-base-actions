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

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../helpers/coverage_helper'
require_relative '../../../lib/armagh/support/string_digest'

class TestStringDigest < Test::Unit::TestCase

  def test_md5
    assert_equal '5luw5ld8t195dpiliva0krvsz', Armagh::Support::StringDigest.md5('hello world')
  end

  def test_md5_with_nil_str
    e = assert_raise(Armagh::Support::StringDigest::StringValueError) do
      Armagh::Support::StringDigest.md5(nil)
    end
    assert_equal 'Input string cannot be nil or empty', e.message
  end

  def test_md5_with_empty_str
    e = assert_raise(Armagh::Support::StringDigest::StringValueError) do
      Armagh::Support::StringDigest.md5('')
    end
    assert_equal 'Input string cannot be nil or empty', e.message
  end

end
