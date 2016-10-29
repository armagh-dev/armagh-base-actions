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


require_relative '../helpers/coverage_helper'

require 'test/unit'
require 'fakefs/safe'

require 'fileutils'

require_relative '../../lib/armagh/support/sftp.rb'

class TestIntegrationSFTP < Test::Unit::TestCase

  SFTP_TEST_DIR = 'sftp'

  NO_ACCESS_DIR = 'no_access_dir'
  READ_ONLY_DIR = 'read_only_sftp_dir'
  READ_WRITE_DIR = 'readwrite_sftp_dir'

  def setup
    local_integration_test_config = load_local_integration_test_config
    @host = local_integration_test_config['test_sftp_host']
    @username = local_integration_test_config['test_sftp_username']
    @password = local_integration_test_config['test_sftp_password']
    @port = local_integration_test_config['test_sftp_port']
    @directory_path = READ_WRITE_DIR

    @config_values = {
      'host' => @host,
      'username' => @username,
      'password' => @password,
      'directory_path' => @directory_path,
      'port' => @port
    }
    @config_store = []
  end

  def teardown
    FakeFS::FileSystem.clear
  end

  def load_local_integration_test_config
    config = nil
    config_filepath = File.join(__dir__, 'local_integration_test_config.json')

    begin
      config = JSON.load(File.read(config_filepath))
      errors = []
      if config.is_a? Hash
        %w(test_sftp_username test_sftp_password test_sftp_host test_sftp_port).each do |k|
          errors << "Config file missing member #{k}" unless config.has_key?(k)
        end
      else
        errors << 'Config file should contain a hash of test_sftp_username, test_sftp_password (Base64 encoded), test_sftp_host, and test_sftp_port'
      end

      if errors.empty?
        config['test_sftp_password'] = Configh::DataTypes::EncodedString.from_encoded(config['test_sftp_password'])
      else
        raise errors.join("\n")
      end
    rescue => e
      puts "Integration test environment not set up.  See test/integration/ftp_test.readme.  Detail: #{ e.message }"
      pend
    end
    config
  end

  def test_validation
    assert_nothing_raised { Armagh::Support::SFTP.create_configuration(@config_store, 'val', {'sftp' => @config_values}) }
  end

  def test_validation_no_write
    config_obj = nil
    @config_values['directory_path'] = READ_ONLY_DIR
    assert_nothing_raised do
      config_obj = Armagh::Support::SFTP.create_configuration(@config_store, 'vnw', {'sftp' => @config_values})
    end
    assert_equal({ "test_connection" => 'SFTP Connection Test Error: The user does not have sufficient permissions to perform the operation. (permission denied)' }, config_obj.test_and_return_errors )
  end

  def test_validation_no_dir
    config_obj = nil
    @config_values['directory_path'] = 'no_such_dir'
    assert_nothing_raised do
     config_obj = Armagh::Support::SFTP.create_configuration(@config_store, 'vnd', {'sftp' => @config_values})
    end
    assert_equal( { "test_connection" => "SFTP Connection Test Error: A reference was made to a file which does not exist. (no such file)" }, config_obj.test_and_return_errors )
  end

  def test_validation_no_access
    config_obj = nil
    @config_values['directory_path'] = NO_ACCESS_DIR
    assert_nothing_raised do
      config_obj = Armagh::Support::SFTP.create_configuration(@config_store, 'vna', {'sftp' => @config_values})
    end
    assert_equal( { "test_connection" => "SFTP Connection Test Error: The user does not have sufficient permissions to perform the operation. (permission denied)" }, config_obj.test_and_return_errors )
  end

  def test_bad_domain
    config_obj = nil
    @config_values['host'] = 'idontexist.kurmudgeon.edd'
    assert_nothing_raised do
      config_obj = Armagh::Support::SFTP.create_configuration(@config_store, 'tbd', {'sftp' => @config_values})
    end
    assert_equal( { "test_connection" => "Unable to resolve host idontexist.kurmudgeon.edd." }, config_obj.test_and_return_errors )
  end

  def test_bad_host
    config_obj = nil
    @config_values['host'] = 'idontexist.kurmudgeon.edu'
    assert_nothing_raised do
      config_obj = Armagh::Support::SFTP.create_configuration(@config_store, 'tbh', {'sftp' => @config_values})
    end
    assert_equal( { "test_connection" => "Unable to resolve host idontexist.kurmudgeon.edu." }, config_obj.test_and_return_errors )
  end

  def test_fail_test_nonexistent_user
    config_obj = nil
    @config_values['username'] = 'idontexisteither'
    assert_nothing_raised do
      config_obj = Armagh::Support::SFTP.create_configuration(@config_store, 'nonexuser', {'sftp' => @config_values})
    end
    assert_equal( { "test_connection" => "Error on host testserver.noragh.com: Authentication failed: Authentication failed for user idontexisteither@testserver.noragh.com" }, config_obj.test_and_return_errors )
  end

  def test_fail_test_wrong_password
    config_obj = nil
    @config_values['password'] = Configh::DataTypes::EncodedString.from_plain_text('NotMyPassword')
    assert_nothing_raised do
      config_obj = Armagh::Support::SFTP.create_configuration(@config_store, 'wrongpass', {'sftp' => @config_values})
    end
    assert_equal( { "test_connection" => "Error on host testserver.noragh.com: Authentication failed: Authentication failed for user ftptest@testserver.noragh.com" }, config_obj.test_and_return_errors )
  end

  def test_put_then_get_files_subdirectories
    @config_values['maximum_transfer'] = 5
    @config_values['filename_pattern'] = '**/*.txt'
    @config_values['create_directory_path' ] = true
    config = Armagh::Support::SFTP.create_configuration(@config_store, 'putget', {'sftp' => @config_values})

    created_files = []
    put_files = []


    FakeFS do
      FileUtils.mkdir_p SFTP_TEST_DIR

      10.times do |i|
        filename = File.join(SFTP_TEST_DIR, "sftp_test_#{i}.txt")
        File.write(filename, "contents of file #{i}")
        created_files << File.join('', filename) # FakeFS puts a leading /
      end

      Armagh::Support::SFTP::Connection.open(config) do |sftp|
        sftp.put_files do |filename, error|
          assert_nil error
          put_files << filename.chomp
        end
      end
    end

    assert_equal(config.sftp.maximum_transfer, put_files.length)
    assert_empty(put_files - created_files)

    FakeFS::FileSystem.clear

    assert_empty FakeFS { Dir.glob(config.sftp.filename_pattern) }

    got_files = []
    files_on_fs = []
    FakeFS do
      Armagh::Support::SFTP::Connection.open(config) do |sftp|
        sftp.get_files do |filename, attributes, error|
          got_files << File.join('', filename) # FakeFS puts a leading /
          assert_not_empty attributes
          assert_kind_of Time, attributes['mtime']
          assert_nil error
        end
      end

      files_on_fs = Dir.glob(config.sftp.filename_pattern)
    end

    assert_equal(config.sftp.maximum_transfer, files_on_fs.length)
    assert_equal(config.sftp.maximum_transfer, got_files.length)
    assert_equal(files_on_fs.sort, got_files.sort)

    no_more_files = true
    Armagh::Support::SFTP::Connection.open(config) do |sftp|
      sftp.get_files do |filename, attributes, error|
        no_more_files = false
      end
    end
    assert_true no_more_files
  ensure
    begin
      Armagh::Support::SFTP::Connection.open(config) do |sftp|
        sftp.rmdir(SFTP_TEST_DIR)
      end
    rescue Armagh::Support::SFTP::FileError
      # ignore
    rescue => e
      puts "ensure error #{e.inspect}"
      raise e unless e.message == 'failure'
    end
  end

  def test_put_then_get_files_root
    @config_values['maximum_transfer'] = 5
    @config_values['filename_pattern'] = '*.txt'
    config = Armagh::Support::SFTP.create_configuration(@config_store, 'putget', {'sftp' => @config_values})

    filename = 'sftp_test_root.txt'
    FakeFS do
      File.write(filename, 'contents of file')
      Armagh::Support::SFTP::Connection.open(config) do |sftp|
        sftp.put_files do |filename, error|
          assert_nil error
        end
      end
    end
    FakeFS::FileSystem.clear
    assert_empty FakeFS { Dir.glob(config.sftp.filename_pattern) }
    files_on_fs = nil

    FakeFS do
      Armagh::Support::SFTP::Connection.open(config) do |sftp|
        sftp.get_files do |filename, attributes, error|
          assert_not_empty attributes
          assert_kind_of Time, attributes['mtime']
          assert_nil error
        end
      end

      files_on_fs = Dir.glob(config.sftp.filename_pattern)
    end

    assert_equal([File.join('', filename)], files_on_fs)
  ensure
    begin
      Armagh::Support::SFTP::Connection.open(config) do |sftp|
        sftp.remove(filename)
      end
    rescue Armagh::Support::SFTP::FileError
      # ignore
    rescue => e
      puts "ensure error #{e.inspect}"
      raise e unless e.message == 'failure'
    end
  end

  def test_put_file_ls_remove
    dest_dir = READ_WRITE_DIR
    @config_values[ 'create_directory_path' ] = true
    files = %w(file1 file2 file3)
    config = Armagh::Support::SFTP.create_configuration(@config_store, 'putget', {'sftp' => @config_values})
    FakeFS do
      files.each { |f| FileUtils.touch f }
    end

    Armagh::Support::SFTP::Connection.open(config) do |sftp|
      FakeFS do
        files.each { |f| sftp.put_file(f, dest_dir) }
      end

      assert_equal(files, sftp.ls(dest_dir))
      sftp.remove(dest_dir)
      ls = sftp.ls('.')
      assert_not_include(ls, dest_dir)
    end
  end
end
    
