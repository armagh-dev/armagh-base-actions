# Copyright 2018 Noragh Analytics, Inc.
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

require_relative '../../../lib/armagh/support/tar'

class TestTar < Test::Unit::TestCase

  def setup
    @test_docs = {}
    10.times do |i|
      @test_docs[ "file_#{i}.txt" ] = "Nakamura Tower, Suite 10#{i}"
    end
  end

  def test_create_tar_file

    result = Armagh::Support::Tar.create_tar_file do |tar|
      @test_docs.each do |filename, content|
        tar.add( filename, content )
      end
    end

    # write to disk to invoke shell tar for test validation
    tmpfile = '/tmp/armagh-base-test-tar.tar'
    begin
      File.open(tmpfile, 'w') { |f| f.write result }
      assert_equal @test_docs.keys, `tar tf #{tmpfile}`.split("\n")
      assert_equal "Nakamura Tower, Suite 100", `tar xOf #{tmpfile} file_0.txt`
    ensure
        File.delete tmpfile
    end
  end

  def test_create_tar_file_write_file

    tmpfile = '/tmp/armagh-base-tar-write-test.tar'

    Armagh::Support::Tar.create_tar_file(tmpfile) do |tar|
      @test_docs.each do |filename, content|
        tar.add( filename, content )
      end
    end

    begin
      assert_equal @test_docs.keys, `tar tf #{tmpfile}`.split("\n")
      assert_equal "Nakamura Tower, Suite 100", `tar xOf #{tmpfile} file_0.txt`
    ensure
      File.delete tmpfile
    end
  end

  def test_create_tgz_file

    result = Armagh::Support::Tar.create_tgz_file do |tar|
      @test_docs.each do |filename, content|
        tar.add( filename, content )
      end
    end

    # write to disk to invoke shell tar for test validation
    tmpfile = '/tmp/armagh-base-test-tar.tgz'
    begin
      File.open(tmpfile, 'w') { |f| f.write result }
      assert_equal @test_docs.keys, `tar ztf #{tmpfile}`.split("\n")
      assert_equal "Nakamura Tower, Suite 100", `tar xOf #{tmpfile} file_0.txt`
    ensure
      File.delete tmpfile
    end
  end


  def test_create_tgz_file_write_file

    tmpfile = '/tmp/armagh-base-tgz-write-test.tgz'

    Armagh::Support::Tar.create_tgz_file(tmpfile) do |tar|
      @test_docs.each do |filename, content|
        tar.add( filename, content )
      end
    end

    begin
      assert_equal @test_docs.keys, `tar ztf #{tmpfile}`.split("\n")
      assert_equal "Nakamura Tower, Suite 100", `tar xOf #{tmpfile} file_0.txt`
    ensure
      File.delete tmpfile
    end
  end

  def test_failure

    StringIO.stubs( :new ).raises( "stringio failed")
    assert_raises Armagh::Support::Tar::TarError, "stringio failed" do
      Armagh::Support::Tar.create_tar_file
    end
  end
end


