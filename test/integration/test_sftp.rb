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

class TestClass
  include Armagh::Support::SFTP
  attr_accessor :parameters
end

class TestIntegrationSFTP < Test::Unit::TestCase

  SFTP_TEST_DIR = 'sftp'

  NO_ACCESS_DIR = 'no_access_dir'
  READ_ONLY_DIR = 'read_only_dir'
  READ_WRITE_DIR = 'readwrite_dir'

  def setup
    local_integration_test_config = load_local_integration_test_config
    @host = local_integration_test_config['test_sftp_host']
    @username = local_integration_test_config['test_sftp_username']
    @password = local_integration_test_config['test_sftp_password']
    @port = local_integration_test_config['test_sftp_port']
    @directory_path = READ_WRITE_DIR

    @parameters = {
      'sftp_host' => @host,
      'sftp_username' => @username,
      'sftp_password' => @password,
      'sftp_directory_path' => @directory_path,
      'sftp_port' => @port
    }
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
        config['test_sftp_password'] = EncodedString.from_encoded(config['test_sftp_password'])
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
    test_class = TestClass.new
    test_class.parameters = @parameters
    result = test_class.custom_validation
    assert_nil result
  end

  def test_validation_no_write
    @parameters['sftp_directory_path'] = READ_ONLY_DIR
    test_class = TestClass.new
    test_class.parameters = @parameters
    result = test_class.custom_validation
    assert_equal 'SFTP Connection Test error: The user does not have sufficient permissions to perform the operation. (permission denied)', result
  end

  def test_validation_no_dir
    @parameters['sftp_directory_path'] = 'no_such_dir'
    test_class = TestClass.new
    test_class.parameters = @parameters
    result = test_class.custom_validation
    assert_equal 'SFTP Connection Test error: A reference was made to a file which does not exist. (no such file)', result
  end

  def test_validation_no_access
    @parameters['sftp_directory_path'] = NO_ACCESS_DIR
    test_class = TestClass.new
    test_class.parameters = @parameters
    result = test_class.custom_validation
    assert_equal 'SFTP Connection Test error: The user does not have sufficient permissions to perform the operation. (permission denied)', result
  end

  def test_bad_domain
    @parameters['sftp_host'] = 'idontexist.kurmudgeon.edd'

    assert_raise(Armagh::Support::SFTP::ConnectionError.new('Unable to resolve host idontexist.kurmudgeon.edd.')) {
      Armagh::Support::SFTP::Connection.open(@parameters) {}
    }
  end

  def test_bad_host
    @parameters['sftp_host'] = 'idontexist.kurmudgeon.edu'
    assert_raise(Armagh::Support::SFTP::ConnectionError.new('Unable to resolve host idontexist.kurmudgeon.edu.')) {
      Armagh::Support::SFTP::Connection.open(@parameters) {}
    }
  end

  def test_fail_test_nonexistent_user
    @parameters['sftp_username'] = 'idontexisteither'
    assert_raise(Armagh::Support::SFTP::ConnectionError.new('Error on host testserver.noragh.com: Authentication failed: Authentication failed for user idontexisteither@testserver.noragh.com')) {
      Armagh::Support::SFTP::Connection.open(@parameters) {}
    }
  end

  def test_fail_test_wrong_password
    @parameters['sftp_password'] = EncodedString.from_plain_text 'NotMyPassword'
    assert_raise(Armagh::Support::SFTP::ConnectionError.new('Error on host testserver.noragh.com: Authentication failed: Authentication failed for user ftptest@testserver.noragh.com')) {
      Armagh::Support::SFTP::Connection.open(@parameters) {}
    }
  end

  def test_put_then_get_files
    @parameters['sftp_maximum_number_to_transfer'] = 5
    @parameters['sftp_filename_pattern'] = '**/*.txt'

    created_files = []
    put_files = []

    FakeFS do
      10.times do |i|
        filename = File.join(SFTP_TEST_DIR, "sftp_test_#{i}.txt")
        FileUtils.mkdir_p SFTP_TEST_DIR
        File.write(filename, "contents of file #{i}")
        created_files << File.join('', filename) # FakeFS puts a leading /
      end

      Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
        sftp.put_files do |filename, error|
          assert_nil error
          put_files << filename.chomp
        end
      end
    end

    assert_equal(@parameters['sftp_maximum_number_to_transfer'], put_files.length)
    assert_empty(put_files - created_files)

    FakeFS::FileSystem.clear

    assert_empty FakeFS { Dir.glob(@parameters['sftp_filename_pattern']) }

    got_files = []
    files_on_fs = []
    FakeFS do
      Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
        sftp.get_files do |filename, error|
          got_files << File.join('', filename) # FakeFS puts a leading /
          assert_nil error
        end
      end

      files_on_fs = Dir.glob(@parameters['sftp_filename_pattern'])
    end

    assert_equal(@parameters['sftp_maximum_number_to_transfer'], files_on_fs.length)
    assert_equal(@parameters['sftp_maximum_number_to_transfer'], got_files.length)
    assert_equal(files_on_fs.sort, got_files.sort)

    no_more_files = true
    Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
      sftp.get_files do |filename, error|
        no_more_files = false
      end
    end
    assert_true no_more_files
  ensure
    begin
      Armagh::Support::SFTP::Connection.open(@parameters) do |sftp|
        sftp.rmdir(SFTP_TEST_DIR)
      end
    rescue Armagh::Support::SFTP::FileError
      # ignore
    end
  end
end
    
