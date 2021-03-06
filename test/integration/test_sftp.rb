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

require_relative '../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'
require 'fakefs/safe'

require 'fileutils'

require_relative '../../lib/armagh/support/sftp.rb'

class TestIntegrationSFTP < Test::Unit::TestCase

  SFTP_TEST_DIR = 'sftp'
  SFTP_DUP_PUT_DIR1 = 'readwrite_sftp_dup_dir1' 
  SFTP_DUP_PUT_DIR2 = 'readwrite_sftp_dup_dir2'

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

  def create_config(name)
    Armagh::Support::SFTP.create_configuration(@config_store, name, {'sftp' => @config_values})
  end

  def test_validation
    assert_nothing_raised { create_config('val') }
  end

  def test_validation_no_write
    @config_values['directory_path'] = READ_ONLY_DIR

    errors = create_config('vna').test_and_return_errors
    message = errors.delete('test_connection')
    assert_empty errors

    assert_include(message, 'SFTP Connection Test Error')
    assert_include(message, 'Permission denied')
  end

  def test_validation_no_access
    @config_values['directory_path'] = NO_ACCESS_DIR

    errors = create_config('vna').test_and_return_errors
    message = errors.delete('test_connection')
    assert_empty errors

    assert_include(message, 'SFTP Connection Test Error')
    assert_include(message, 'Permission denied')
  end

  def test_bad_domain_via_validation_callback
    @config_values['host'] = 'idontexist.kurmudgeon.edd'

    assert_equal(
      {'test_connection'=>'Unable to resolve host idontexist.kurmudgeon.edd.'},
      create_config('tbd').test_and_return_errors
    )
  end

  def test_bad_domain_via_test_callback
    config_obj = nil
    @config_values['host'] = 'idontexist.kurmudgeon.edd'
    Armagh::Support::SFTP.stubs(:test_connection)
    assert_nothing_raised { config_obj = create_config('tbd') }
    Armagh::Support::SFTP.unstub(:test_connection)
    assert_equal( { "test_connection" => "Unable to resolve host idontexist.kurmudgeon.edd." }, config_obj.test_and_return_errors )
  end

  def test_bad_host
    @config_values['host'] = 'idontexist.kurmudgeon.edu'

    assert_equal(
      {'test_connection'=>'Unable to resolve host idontexist.kurmudgeon.edu.'},
      create_config('tbh').test_and_return_errors
    )
  end

  def test_fail_test_nonexistent_user
    @config_values['username'] = 'idontexisteither'

    assert_equal(
      {'test_connection'=>'Error on host testserver.noragh.com: Authentication failed: Authentication failed for user idontexisteither@testserver.noragh.com'},
      create_config('nonexuser').test_and_return_errors
    )
  end

  def test_fail_test_wrong_password
    @config_values['password'] = Configh::DataTypes::EncodedString.from_plain_text('NotMyPassword')

    assert_equal(
      {'test_connection'=>'Error on host testserver.noragh.com: Authentication failed: Authentication failed for user ftptest@testserver.noragh.com'},
      create_config('wrongpass').test_and_return_errors
    )
  end

  def test_put_then_get_files_subdirectories
    @config_values['maximum_transfer'] = 5
    @config_values['filename_pattern'] = '**/*.txt'
    @config_values['duplicate_put_directory_paths'] = [ SFTP_DUP_PUT_DIR1, SFTP_DUP_PUT_DIR2 ]
    config = Armagh::Support::SFTP.create_configuration(@config_store, 'putget', {'sftp' => @config_values})

    created_files = []
    put_files = []
    errors =[]

    FakeFS do
      FileUtils.mkdir_p SFTP_TEST_DIR

      10.times do |i|
        filename = File.join(SFTP_TEST_DIR, "sftp_test_#{i}.txt")
        File.write(filename, "contents of file #{i}")
        created_files << File.join('', filename) # FakeFS puts a leading /
      end

      Armagh::Support::SFTP::Connection.open(config) do |sftp|
        sftp.put_files do |filename, error|
          errors << error unless error.nil?
          put_files << filename.chomp
        end
      end
    end

    assert_equal(config.sftp.maximum_transfer, put_files.length)
    assert_empty(put_files - created_files)
    assert_empty(errors)

    @config_values.delete 'duplicate_put_directory_paths'

    [ READ_WRITE_DIR, SFTP_DUP_PUT_DIR1, SFTP_DUP_PUT_DIR2 ].each do |from_dir|
      @config_values['directory_path'] = from_dir
      getter_config = Armagh::Support::SFTP.create_configuration(@config_store, "get_put_#{from_dir}", {'sftp' => @config_values})

      FakeFS::FileSystem.clear
      assert_empty FakeFS { Dir.glob(getter_config.sftp.filename_pattern) }

      got_files = []
      files_on_fs = []
      FakeFS do
        Armagh::Support::SFTP::Connection.open(getter_config) do |sftp|
          sftp.get_files do |filename, attributes, error|
            got_files << File.join('', filename) # FakeFS puts a leading /
            assert_not_empty attributes
            assert_kind_of Time, attributes['mtime']
            assert_nil error
          end
        end

        files_on_fs = Dir.glob(getter_config.sftp.filename_pattern)
      end

      assert_equal(getter_config.sftp.maximum_transfer, files_on_fs.length)
      assert_equal(getter_config.sftp.maximum_transfer, got_files.length)
      assert_equal(files_on_fs.sort, got_files.sort)

      no_more_files = true
      Armagh::Support::SFTP::Connection.open(getter_config) do |sftp|
        sftp.get_files do |filename, attributes, error|
          no_more_files = false
        end
      end
      assert_true no_more_files
    end
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
        sftp.put_files do |_filename, error|
          assert_nil error
        end
      end
    end
    FakeFS::FileSystem.clear
    assert_empty FakeFS { Dir.glob(config.sftp.filename_pattern) }
    files_on_fs = nil

    FakeFS do
      Armagh::Support::SFTP::Connection.open(config) do |sftp|
        sftp.get_files do |_filename, attributes, error|
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
        sftp.remove_subpath(filename)
      end
    rescue Armagh::Support::SFTP::FileError
      # ignore
    rescue => e
      puts "ensure error #{e.inspect}"
      raise e unless e.message == 'failure'
    end
  end

  def test_put_file_ls_remove
    dest_subdir = 'subdir'

    files = %w(file1 file2 file3)
    config = Armagh::Support::SFTP.create_configuration(@config_store, 'putget', {'sftp' => @config_values})

    FakeFS do 
      files.each { |f| FileUtils.touch f }

      Armagh::Support::SFTP::Connection.open(config) do |sftp|
        files.each { |f| sftp.put_file(f, dest_subdir) }

        assert_equal(files, sftp.ls_subdir(dest_subdir))
        sftp.remove_subpath(dest_subdir)
        ls = sftp.ls_subdir( '.')
        assert_not_include(ls, dest_subdir)
      end
    end
  end

  def test_test_connection_creates_dir
    new_subdir = 'test_creates_and_removes_this_dir'
    config = Armagh::Support::SFTP.create_configuration(@config_store, 'chkdir', {'sftp' => @config_values})

    Armagh::Support::SFTP::Connection.open(config) do |sftp|
      ls = sftp.ls_subdir('.')
      assert_not_include(ls, new_subdir)
    end

    @config_values['directory_path'] = File.join(READ_WRITE_DIR, new_subdir)
    assert_empty create_config('vcd').test_and_return_errors

    Armagh::Support::SFTP::Connection.open(config) do |sftp|
      ls = sftp.ls_subdir('.')
      assert_include(ls, new_subdir)
    end

    ensure
      Armagh::Support::SFTP::Connection.open(config) do |sftp|
        sftp.remove_subpath(new_subdir)
      end
  end

  def test_use_default_filename_pattern
    dest_subdir = 'test_default_pattern'

    @config_values['directory_path'] = File.join(READ_WRITE_DIR, dest_subdir)
    config = Armagh::Support::SFTP.create_configuration(@config_store, 'putget', {'sftp' => @config_values})

    ls_before = nil
    ls_after = nil
    files = %w(file1 file2 file3)
    FakeFS do
      files.each { |f| FileUtils.touch f }
      Armagh::Support::SFTP::Connection.open(config) do |sftp|
        ls_before = sftp.ls(READ_WRITE_DIR)
        sftp.put_files
        ls_after = sftp.ls_subdir('.')
      end
    end

    assert_not_include(ls_before, dest_subdir)
    assert_equal(files, ls_after)
    FakeFS::FileSystem.clear

    target_files = []
    FakeFS do
      Armagh::Support::SFTP::Connection.open(config) do |sftp|
        sftp.get_files do |filename, attributes, error|
          target_files << filename
          assert_not_empty attributes
          assert_kind_of Time, attributes['mtime']
          assert_nil error
        end
      end
    end

    assert_equal(files.sort, target_files.sort)

    ensure
      begin
        Armagh::Support::SFTP::Connection.open(config) do |sftp|
          sftp.remove(File.join(READ_WRITE_DIR, dest_subdir))
        end
      rescue Armagh::Support::SFTP::FileError
        # ignore
      rescue => e
        puts "ensure error #{e.inspect}"
        raise e unless e.message == 'failure'
      end
    end

end

