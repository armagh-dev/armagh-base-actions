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

require_relative '../../../lib/armagh/support/decompress'

class TestDecompress < Test::Unit::TestCase

  def test_decompress
    str = "\u001F\x8B\b\b\x9A~\xA4Y\u0000\u0003file.txt\u0000+\xCE\xCFMU(.)\xCA\xCCK\xE7\u0002\u0000\xFB\xA2\x99 \f\u0000\u0000\u0000"
    assert_equal("some string\n", Armagh::Support::Decompress.decompress(str))
  end

  def test_decompress_uncompressed
    str = 'Some non-compressed string'
    assert_raise(Armagh::Support::Decompress::DecompressError.new('Unable to decompress string.')) do
      Armagh::Support::Decompress.decompress(str)
    end
  end
end
