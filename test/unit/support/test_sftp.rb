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
require 'fakefs/safe'
require 'fileutils'

require 'net/sftp'
require 'armagh/common/encoded_string'

require_relative '../../../lib/armagh/actions/collect.rb'
require_relative '../../../lib/armagh/actions/consume.rb'
require_relative '../../../lib/armagh/support/sftp.rb'

class SFTPTestAction < Armagh::Actions::Action
  include Armagh::Support::SFTP
  attr_accessor :parameters
end

class UnknownSSHError < Net::SSH::Exception; end

class TestSFTP < Test::Unit::TestCase

  def setup
    @parameters = {
      'sftp_maximum_number_to_transfer' => 4,
      'sftp_directory_path' => '/',
      'sftp_password' => EncodedString.from_plain_text('password_123'),
      'sftp_username' => 'test_user',
    }

    @mocked_sftp_lib = mock('sftp')
    Net::SFTP.stubs(start: @mocked_sftp_lib)
  end

  def teardown
    FakeFS::FileSystem.clear
  end

  def assert_start_error(cause_class, expected_class)
    Net::SFTP.expects(:start).raises(cause_class.new)
    assert_raise(expected_class) { Armagh::Support::SFTP::Connection.open(@parameters) {} }
  end

  def assert_sftp_start_status_error(error_code, expected_class)
    response = stub ({code: error_code, message: nil})
    e = Net::SFTP::StatusException.new response
    Net::SFTP.expects(:start).raises(e)
    assert_raise(expected_class) { Armagh::Support::SFTP::Connection.open(@parameters) {} }
  end

  def stub_close
    session = stub(closed?: false, close: nil)
    @mocked_sftp_lib.stubs(session: session)
  end

  def make_entries
    entries = []
    expected_files = []

    5.times do |i|
      name = "entry_#{i}"
      entry = mock(name)
      entry.expects(:file?).returns(i != 2)
      unless i == 2
        entry.expects(:name).returns(name)
        expected_files << name
      end

      entries << entry
    end

    return entries, expected_files
  end

  def make_files
    files = []
    5.times do |i|
      name = "file_#{i}"
      if i == 2
        FileUtils.mkdir name
      else
        File.write(name, "File #{i} content")
        files << File.join('', name)
      end
    end
    files
  end

  def test_custom_validation
    action = SFTPTestAction.new('', mock('caller'), 'logger', {}, mock)
    Armagh::Support::SFTP::Connection.any_instance.expects(:test_connection)
    Armagh::Support::SFTP::Connection.any_instance.expects(:close)
    action.custom_validation
  end

  def test_error_handler
    assert_start_error(RuntimeError, Armagh::Support::SFTP::SFTPError)
    assert_start_error(SocketError, Armagh::Support::SFTP::ConnectionError)
    assert_start_error(Errno::ECONNREFUSED, Armagh::Support::SFTP::ConnectionError)
  end

  def test_ssh_error_handler
    assert_start_error(Net::SSH::AuthenticationFailed, Armagh::Support::SFTP::ConnectionError)
    assert_start_error(Net::SSH::ConnectionTimeout, Armagh::Support::SFTP::TimeoutError)
    assert_start_error(Net::SSH::Timeout, Armagh::Support::SFTP::TimeoutError)
    assert_start_error(Net::SSH::Disconnect, Armagh::Support::SFTP::ConnectionError)
    assert_start_error(Net::SSH::HostKeyError, Armagh::Support::SFTP::ConnectionError)
    assert_start_error(UnknownSSHError, Armagh::Support::SFTP::SFTPError)
  end

  def test_sftp_error_handler
    assert_sftp_start_status_error(1, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(2, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(3, Armagh::Support::SFTP::PermissionError)
    assert_sftp_start_status_error(4, Armagh::Support::SFTP::SFTPError)
    assert_sftp_start_status_error(5, Armagh::Support::SFTP::SFTPError)
    assert_sftp_start_status_error(6, Armagh::Support::SFTP::ConnectionError)
    assert_sftp_start_status_error(7, Armagh::Support::SFTP::ConnectionError)
    assert_sftp_start_status_error(8, Armagh::Support::SFTP::SFTPError)
    assert_sftp_start_status_error(9, Armagh::Support::SFTP::FileError)

    assert_sftp_start_status_error(10, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(11, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(12, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(13, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(14, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(15, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(16, Armagh::Support::SFTP::PermissionError)
    assert_sftp_start_status_error(17, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(18, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(19, Armagh::Support::SFTP::FileError)

    assert_sftp_start_status_error(20, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(21, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(22, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(23, Armagh::Support::SFTP::SFTPError)
    assert_sftp_start_status_error(24, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(25, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(26, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(27, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(28, Armagh::Support::SFTP::FileError)
    assert_sftp_start_status_error(29, Armagh::Support::SFTP::PermissionError)

    assert_sftp_start_status_error(30, Armagh::Support::SFTP::PermissionError)
    assert_sftp_start_status_error(31, Armagh::Support::SFTP::FileError)

    assert_sftp_start_status_error(999, Armagh::Support::SFTP::SFTPError)
  end

  def test_get_files_with_a_failure
    entries, expected_files = make_entries

    stub_close

    dir = mock('dir')
    dir.expects(:glob).returns(entries)
    @mocked_sftp_lib.expects(:dir).returns(dir)

    @mocked_sftp_lib.expects(:download!).with('/entry_0', 'entry_0')
    @mocked_sftp_lib.expects(:remove!).with('/entry_0')

    @mocked_sftp_lib.expects(:download!).with('/entry_1', 'entry_1').raises(RuntimeError.new).times(3)

    @mocked_sftp_lib.expects(:download!).with('/entry_3', 'entry_3')
    @mocked_sftp_lib.expects(:remove!).with('/entry_3')

    @mocked_sftp_lib.expects(:download!).with('/entry_4', 'entry_4')
    @mocked_sftp_lib.expects(:remove!).with('/entry_4')

    seen_errors = []

    Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
      sftp.get_files { |file, error|
        expected_files.delete(file)
        seen_errors << error if error
      }
    end

    assert_empty expected_files
    assert_equal 1, seen_errors.length

    assert_kind_of(Armagh::Support::SFTP::SFTPError, seen_errors.first)
  end

  def test_get_files_system_failure
    entries, _expected_files = make_entries
    entries.last.unstub(:name) # We'll never get to the last one

    stub_close

    dir = mock('dir')
    dir.expects(:glob).returns(entries)

    @mocked_sftp_lib.expects(:dir).returns(dir)

    @mocked_sftp_lib.expects(:download!).raises(RuntimeError.new).at_least_once

    assert_raise(Armagh::Support::SFTP::SFTPError.new('Three files failed in a row.  Aborting.')) do
      Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
        sftp.get_files { |file, error|}
      end
    end
  end

  def test_put_files_with_a_failure
    path = stub(:directory? => true)
    @mocked_sftp_lib.expects(:stat!).returns(path).at_least_once

    @mocked_sftp_lib.expects(:upload!).with('/file_0', '/file_0')
    @mocked_sftp_lib.expects(:upload!).with('/file_1', '/file_1').raises(RuntimeError.new).times(3)
    @mocked_sftp_lib.expects(:upload!).with('/file_3', '/file_3')
    @mocked_sftp_lib.expects(:upload!).with('/file_4', '/file_4')

    stub_close

    files = nil
    seen_errors = []

    FakeFS do
      puts Dir.glob('*')
      files = make_files

      Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
        sftp.put_files do |file, error|
          files.delete(file)
          seen_errors << error if error
        end
      end
    end

    assert_empty files
    assert_equal 1, seen_errors.size
    assert_kind_of Armagh::Support::SFTP::SFTPError, seen_errors.first
  end

  def test_put_files_system_failure
    @mocked_sftp_lib.expects(:stat!).raises(RuntimeError.new).at_least_once

    stub_close

    assert_raise(Armagh::Support::SFTP::SFTPError.new('Three files failed in a row.  Aborting.')) do
      Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
        sftp.put_files { |file, error|}
      end
    end
  end

  def test_test_connection
    @mocked_sftp_lib.expects(:upload!).with do |local, remote|
      @mocked_sftp_lib.expects(:remove!).with(remote)
    end

    stub_close

    result = 'placeholder'
    Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
      result = sftp.test_connection
    end
    assert_nil result
  end

  def test_test_connection_bad
    @mocked_sftp_lib.expects(:upload!).raises(RuntimeError.new)
    stub_close
    result = 'placeholder'
    Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
      result = sftp.test_connection
    end
    assert_equal 'SFTP Connection Test error: Unexpected SFTP error from host : RuntimeError', result
  end

  def test_mkdir_p
    dir = stub(directory?: true)
    no_file_error = Net::SFTP::StatusException.new(stub({code: 2, message: nil}))

    stub_close

    @mocked_sftp_lib.expects(:stat!).with('/').returns(dir)
    @mocked_sftp_lib.expects(:stat!).with('/make').returns(dir)
    @mocked_sftp_lib.expects(:stat!).with('/make/some').raises(no_file_error)
    @mocked_sftp_lib.expects(:mkdir!).with('/make/some')
    @mocked_sftp_lib.expects(:stat!).with('/make/some/path').raises(no_file_error)
    @mocked_sftp_lib.expects(:mkdir!).with('/make/some/path')
    Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
      sftp.mkdir_p('/make/some/path')
    end
  end

  def test_mkdir_p_existing_file_as_path
    dir = stub(directory?: true)
    file = stub(directory?: false)

    stub_close

    @mocked_sftp_lib.expects(:stat!).with('/').returns(dir)
    @mocked_sftp_lib.expects(:stat!).with('/make').returns(file)
    assert_raise(Armagh::Support::SFTP::FileError.new('Could not create /make/some/path.  /make is a file.')) do
      Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
        sftp.mkdir_p('/make/some/path')
      end
    end
  end

  def test_mkdir_p_unknown_error
    stub_close

    @mocked_sftp_lib.expects(:stat!).with('/').raises(RuntimeError.new('error'))
    assert_raise(Armagh::Support::SFTP::SFTPError) do
      Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
        sftp.mkdir_p('/make/some/path')
      end
    end
  end

  def test_mkdir_p_unknown_status
    stub_close

    unknown_error = Net::SFTP::StatusException.new(stub({code: 123, message: nil}))
    @mocked_sftp_lib.expects(:stat!).with('/').raises(unknown_error)
    assert_raise(Armagh::Support::SFTP::SFTPError) do
      Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
        sftp.mkdir_p('/make/some/path')
      end
    end
  end

  def test_rmdir
    stub_close
    @mocked_sftp_lib.expects(:rmdir!).with('/path')
    Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
      sftp.rmdir('path')
    end
  end

  def test_rmdir_error
    stub_close
    @mocked_sftp_lib.expects(:rmdir!).raises(RuntimeError.new)
    assert_raise(Armagh::Support::SFTP::SFTPError) do
      Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
        sftp.rmdir('path')
      end
    end
  end

  def test_sftp_key
    stub_close
    @parameters.delete('password')
    @parameters['sftp_key'] = 'some key'

    FakeFS do
      Armagh::Support::SFTP::Connection.open(@parameters) { |sftp|}
      assert_equal(@parameters['sftp_key'], File.read('.ssh_key'))
    end
  end
end