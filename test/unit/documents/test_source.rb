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

require_relative '../../../lib/armagh/documents/source'

class TestSource < Test::Unit::TestCase

	def setup
    @type = 'type'
    @filename = 'filename'
    @path = 'path'
    @host = 'host'
    @mtime = 'mtime'
    @url = 'url'
    @encoding = 'encoding'
    @mime_type = 'mime_type'

    @source = Armagh::Documents::Source.new(type: @type,
                                             filename: @filename,
                                             path: @path,
                                             host: @host,
                                             mtime: @mtime,
                                             url: @url,
                                             encoding: @encoding,
                                             mime_type: @mime_type)
  end

  def test_dbleq
    @same_source = Armagh::Documents::Source.new(type: @type,
                                            filename: @filename,
                                            path: @path,
                                            host: @host,
                                            mtime: @mtime,
                                            url: @url,
                                            encoding: @encoding,
                                            mime_type: @mime_type)
    assert_true @same_source == @source
    @same_source.host = nil
    assert_false @same_source == @source
  end

  def test_eql?
    @same_source = Armagh::Documents::Source.new(type: @type,
                                                 filename: @filename,
                                                 path: @path,
                                                 host: @host,
                                                 mtime: @mtime,
                                                 url: @url,
                                                 encoding: @encoding,
                                                 mime_type: @mime_type)
    assert_true @same_source.eql? @source
    @same_source.host = nil
    assert_false @same_source.eql? @source
  end

  def test_hash
    hash = @source.to_hash
    @new_source = Armagh::Documents::Source.from_hash(hash)
    assert_equal(@source, @new_source)
  end

end
