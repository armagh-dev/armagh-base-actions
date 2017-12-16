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

require_relative '../../../lib/armagh/support/compress'
require_relative '../../../lib/armagh/support/decompress'

class TestCompress < Test::Unit::TestCase

  def test_compress
    test_string = "I've been through the wringer".freeze
    assert_equal test_string, Armagh::Support::Decompress.decompress(Armagh::Support::Compress.compress(test_string))
  end

  def test_compress_fails
    Zlib.stubs(:compress).raises("oops")
    assert_raises Armagh::Support::Decompress::DecompressError, "oops" do
      Armagh::Support::Decompress.decompress('me')
    end
  end
end
