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
require 'fakefs/safe'
require 'fileutils'

require 'net/sftp'

require_relative '../../../lib/armagh/actions/collect.rb'
require_relative '../../../lib/armagh/actions/consume.rb'
require_relative '../../../lib/armagh/support/sftp.rb'

class UnknownSSHError < Net::SSH::Exception;
end

class TestSFTP < Test::Unit::TestCase

  def setup
    session = mock
    session.stubs('close')
    session.stubs(closed?: false)
    @mocked_sftp_lib = stub('sftp')
    @mocked_sftp_lib.stubs('upload!')
    @mocked_sftp_lib.stubs('remove!')
    @mocked_sftp_lib.stubs(session: session)
    Net::SFTP.stubs(start: @mocked_sftp_lib)
    @config_values = {
      'host' => 'localhost',
      'maximum_transfer' => 4,
      'directory_path' => '/',
      'create_directory_path' => true,
      'password' => Configh::DataTypes::EncodedString.from_plain_text('password_123'),
      'username' => 'test_user'
    }
    @config_store = []
    @config = Armagh::Support::SFTP.create_configuration(@config_store, 'fred', {'sftp' => @config_values})
  end

  def teardown
    FakeFS::FileSystem.clear
  end

  def assert_start_error(cause_class, expected_class)

    Net::SFTP.stubs(:start).raises(cause_class.new)
    assert_raise(expected_class) { Armagh::Support::SFTP::Connection.open(@config) { |conn|} }
  end

  def assert_sftp_start_status_error(error_code, expected_class)
    response = stub ({code: error_code, message: nil})
    e = Net::SFTP::StatusException.new response
    Net::SFTP.stubs(:start).raises(e)
    assert_raise(expected_class) { Armagh::Support::SFTP::Connection.open(@config) { |conn|} }
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

      attributes = stub('attributes')
      attributes.stubs(attributes: {})
      entry.stubs(attributes: attributes)

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
    Armagh::Support::SFTP::Connection.any_instance.expects(:test_connection)
    Armagh::Support::SFTP::Connection.any_instance.expects(:close)
    config = Armagh::Support::SFTP.create_configuration(@config_store, 'w', {'sftp' => @config_values})
    config.test_and_return_errors
  end

  def test_custom_validation_exception
    e = RuntimeError.new('ERROR!')
    Armagh::Support::SFTP::Connection.any_instance.expects(:test_connection).returns( 'boom')
    config = nil
    assert_nothing_raised do
      config = Armagh::Support::SFTP.create_configuration(@config_store, 'bad', {'sftp' => @config_values})
    end
    assert_equal( { "test_connection" => "boom" }, config.test_and_return_errors)
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

    Armagh::Support::SFTP::Connection.open(@config) do |sftp|
      sftp.get_files { |file, attributes, error|
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
      Armagh::Support::SFTP::Connection.open(@config) do |sftp|
        sftp.get_files { |file, attributes, error|}
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

      Armagh::Support::SFTP::Connection.open(@config) do |sftp|
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
    path = stub(:directory? => true)
    @mocked_sftp_lib.expects(:stat!).returns(path).at_least_once
    @mocked_sftp_lib.expects(:upload!).raises(RuntimeError.new).at_least_once

    stub_close

    assert_raise(Armagh::Support::SFTP::SFTPError.new('Three files failed in a row.  Aborting.')) do
      Armagh::Support::SFTP::Connection.open(@config) do |sftp|
        sftp.put_files { |file, error| }
      end
    end
  end

  def test_put_files_mkdir_failure
    @mocked_sftp_lib.expects(:stat!).raises(RuntimeError.new).at_least_once

    stub_close

    assert_raise(Armagh::Support::SFTP::SFTPError.new('Three files failed in a row.  Aborting.')) do
      Armagh::Support::SFTP::Connection.open(@config) do |sftp|
        sftp.put_files { |file, error| }
      end
    end
  end

  def test_put_file
    file = 'file'
    path = '.'
    stat_result = stub(:directory? => true)
    @mocked_sftp_lib.expects(:stat!).returns(stat_result).at_least_once
    @mocked_sftp_lib.expects(:upload!).with(file, File.join(@config.sftp.directory_path, path, File.dirname(file), file))
    FakeFS do
      FileUtils.touch(file)

      Armagh::Support::SFTP::Connection.open(@config) do |sftp|
        sftp.put_file(file, path)
      end
    end
  end
  
  def test_put_file_with_duplicates
    file = 'subd/file'
    path = '.'
    stat_result = stub(:directory? => true)
    dup_config_values = @config_values.merge( { 'duplicate_put_directory_paths' => [ 'dup1', 'dup2' ]}) 
    dup_config = Armagh::Support::SFTP.create_configuration(@config_store, 'fred2', {'sftp' => dup_config_values})

    @mocked_sftp_lib.expects(:stat!).returns(stat_result).at_least_once
    @mocked_sftp_lib.expects(:upload!).with( file, File.join(dup_config.sftp.directory_path, path, file))
    @mocked_sftp_lib.expects(:upload!).with( file, File.join(dup_config.sftp.duplicate_put_directory_paths.first, path, file ))
    @mocked_sftp_lib.expects(:upload!).with( file, File.join(dup_config.sftp.duplicate_put_directory_paths.last, path, file ))
    
    FakeFS do
      FileUtils.mkdir_p File.dirname(file)
      FileUtils.touch(file)

      Armagh::Support::SFTP::Connection.open(dup_config) do |sftp|
        sftp.put_file(file, path)
      end
    end
  end
    
  def test_put_file_not_file
    @mocked_sftp_lib.expects(:upload!).never
    assert_raise(Armagh::Support::SFTP::FileError.new("Local file 'invalid' is not a file.")) do
      Armagh::Support::SFTP::Connection.open(@config) do |sftp|
        sftp.put_file('invalid', '.')
      end
    end
  end

  def test_put_file_error
    file = 'file'
    path = '.'
    stat_result = stub(:directory? => true)
    @mocked_sftp_lib.expects(:stat!).returns(stat_result).at_least_once
    @mocked_sftp_lib.expects(:upload!).raises(RuntimeError.new('ERROR')).times(3)

    assert_raise(Armagh::Support::SFTP::SFTPError.new('Unexpected SFTP error from host localhost: ERROR')) do
      FakeFS do
        FileUtils.touch(file)
        Armagh::Support::SFTP::Connection.open(@config) do |sftp|
          sftp.put_file(file, path)
        end
      end
    end
  end

  def test_remove_subpath
    session = mock
    @mocked_sftp_lib.expects(:session).returns session
    session.expects(:exec!).with('rm -rf /something')

    Armagh::Support::SFTP::Connection.open(@config) do |sftp|
      sftp.remove_subpath('something')
    end
  end

  def test_remove_error
    @mocked_sftp_lib.expects(:session).raises(RuntimeError.new('ERROR'))

    assert_raise(Armagh::Support::SFTP::SFTPError.new('Unexpected SFTP error from host localhost: ERROR')) do
      Armagh::Support::SFTP::Connection.open(@config) do |sftp|
        sftp.remove_subpath('something')
      end
    end
  end


  def test_test_connection
    @mocked_sftp_lib.stubs(:upload!).with do |local, remote|
      @mocked_sftp_lib.stubs(:remove!).with(remote)
    end

    stub_close

    result = 'placeholder'
    Armagh::Support::SFTP::Connection.open(@config) do |sftp|
      result = sftp.test_connection
    end
    assert_nil result
  end

  def test_test_connection_bad
    Armagh::Support::SFTP::Connection.any_instance.stubs(:mksubdir_p)
    @mocked_sftp_lib.stubs(:upload!).raises(RuntimeError.new)
    stub_close
    result = 'placeholder'
    Armagh::Support::SFTP::Connection.open(@config) do |sftp|
      result = sftp.test_connection
    end
    assert_equal 'SFTP Connection Test Error: Unexpected SFTP error from host : RuntimeError', result
  end

  def test_mksubdir_p
    dir = stub(directory?: true)
    no_file_error = Net::SFTP::StatusException.new(stub({code: 2, message: nil}))

    stub_close

    @mocked_sftp_lib.expects(:stat!).with('/').returns(dir)
    @mocked_sftp_lib.expects(:stat!).with('/make').returns(dir)
    @mocked_sftp_lib.expects(:stat!).with('/make/some').raises(no_file_error)
    @mocked_sftp_lib.expects(:mkdir!).with('/make/some')
    @mocked_sftp_lib.expects(:stat!).with('/make/some/path').raises(no_file_error)
    @mocked_sftp_lib.expects(:mkdir!).with('/make/some/path')
    Armagh::Support::SFTP::Connection.open(@config) do |sftp|
      sftp.mksubdir_p('/make/some/path')
    end
  end

  def test_mksubdir_p_existing_file_as_path
    dir = stub(directory?: true)
    file = stub(directory?: false)

    stub_close

    @mocked_sftp_lib.expects(:stat!).with('/').returns(dir)
    @mocked_sftp_lib.expects(:stat!).with('/make').returns(file)
    assert_raise(Armagh::Support::SFTP::FileError.new('Could not create /make/some/path.  /make is a file.')) do
      Armagh::Support::SFTP::Connection.open(@config) do |sftp|
        sftp.mksubdir_p('/make/some/path')
      end
    end
  end

  def test_mksubdir_p_unknown_error
    stub_close

    @mocked_sftp_lib.expects(:stat!).with('/').raises(RuntimeError.new('error'))
    assert_raise(Armagh::Support::SFTP::SFTPError) do
      Armagh::Support::SFTP::Connection.open(@config) do |sftp|
        sftp.mksubdir_p('/make/some/path')
      end
    end
  end

  def test_mksubdir_p_unknown_status
    stub_close

    unknown_error = Net::SFTP::StatusException.new(stub({code: 123, message: nil}))
    @mocked_sftp_lib.expects(:stat!).with('/').raises(unknown_error)
    assert_raise(Armagh::Support::SFTP::SFTPError) do
      Armagh::Support::SFTP::Connection.open(@config) do |sftp|
        sftp.mksubdir_p('/make/some/path')
      end
    end
  end

  def test_rmsubdir
    stub_close
    @mocked_sftp_lib.expects(:rmdir!).with('/path')
    Armagh::Support::SFTP::Connection.open(@config) do |sftp|
      sftp.rmsubdir('path')
    end
  end

  def test_rmsubdir_error
    stub_close
    @mocked_sftp_lib.expects(:rmdir!).raises(RuntimeError.new)
    assert_raise(Armagh::Support::SFTP::SFTPError) do
      Armagh::Support::SFTP::Connection.open(@config) do |sftp|
        sftp.rmsubdir('path')
      end
    end
  end

  def test_ls_subdir
    path = 'path'
    dir = mock
    stub_close
    @mocked_sftp_lib.expects(:dir).returns(dir)
    entries = [
      mock(name: 'name1'),
      mock(name: 'name2'),
      mock(name: 'name3'),
    ]
    dir.expects(:entries).with(File.join(@config.sftp.directory_path, path)).returns(entries)
    listing = nil

    Armagh::Support::SFTP::Connection.open(@config) do |sftp|
      listing = sftp.ls_subdir(path)
    end

    assert_equal(%w(name1 name2 name3), listing)
  end

  def test_ls_subdir_error
    @mocked_sftp_lib.expects(:dir).raises(RuntimeError.new('ERROR'))
    assert_raise(Armagh::Support::SFTP::SFTPError.new('Unexpected SFTP error from host localhost: ERROR')) do
      Armagh::Support::SFTP::Connection.open(@config) do |sftp|
        sftp.ls_subdir('.')
      end
    end
  end

  def test_sftp_key
    stub_close
    test_config_values = Marshal.load(Marshal.dump(@config_values))
    test_config_values.delete 'password'
    test_config_values['key'] = 'some key'

    FakeFS do
      Dir.mkdir('/tmp')
      c = Armagh::Support::SFTP.create_configuration(@config_store, 'sftpkey', {'sftp' => test_config_values}) { |sftp|}
      c.test_and_return_errors
      assert_equal(c.sftp.key, File.read('.ssh_key'))
    end
  end

  def test_archive_config
    host = 'hostname'
    path = '/archive/dir'
    user = 'armagh_user'
    ENV.expects(:[]).with('ARMAGH_ARCHIVE_HOST').returns(host)
    ENV.expects(:[]).with('ARMAGH_ARCHIVE_PORT').returns(nil)
    ENV.expects(:[]).with('ARMAGH_ARCHIVE_PATH').returns(path)
    ENV.expects(:[]).with('ARMAGH_ARCHIVE_USER').returns(user)

    config = Armagh::Support::SFTP.archive_config
    assert_same(config, Armagh::Support::SFTP.archive_config)

    assert_equal host, config.sftp.host
    assert_equal path, config.sftp.directory_path
    assert_equal user, config.sftp.username
  end
end
