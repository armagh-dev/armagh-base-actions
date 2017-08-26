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

require_relative '../../../lib/armagh/support/ftp.rb'

class TestFTP < Test::Unit::TestCase

  def setup

    @logger = mock
    @caller = mock

    @test_ftp_host           = 'testserver'
    @test_ftp_username       = 'myftpuser'
    @test_ftp_password       = Configh::DataTypes::EncodedString.from_plain_text( 'MyFtpPassword' )
    @test_ftp_directory_path = 'readable_test_dir'

    @config_store = []

    config_defaults_ftp = {
      'port'              => 21,
      'directory_path'    => './',
      'passive_mode'      => true,
      'maximum_transfer'  => 50,
      'open_timeout'      => 30,
      'read_timeout'      => 60,
      'delete_on_put'     => false
    }

    @base_valid_config = {

      'ftp' => config_defaults_ftp.merge({
                'host'           => @test_ftp_host,
                'username'       => @test_ftp_username,
                'password'       => @test_ftp_password,
                'directory_path' => @test_ftp_directory_path,
       })
     }

    @mock_ftp = mock('Ftp server')
    @mock_ftp.stubs(:passive=)
    @mock_ftp.stubs(:open_timeout=)
    @mock_ftp.stubs(:read_timeout=)

  end

  def teardown
    FakeFS::FileSystem.clear
  end

  def merge_config_values( values1, values2 )

    return values1 if values2.nil?

    static_values = values1.dup
    values2.each do |grp,grp_hash|

      grp_hash.each do |pname, new_val|

        if new_val
          static_values[ grp ][ pname ] = new_val
        else
          static_values[ grp ].delete pname
        end
      end
    end
    static_values
  end

  def assert_create_configuration_returns_config_or_errors( changed_params, expected_errors )
    static_values = merge_config_values( @base_valid_config, changed_params )

    check_errors = nil
    config       = nil
    Armagh::Support::FTP.stubs(:ftp_validation)
    begin
      config = Armagh::Support::FTP.create_configuration( @config_store, 'fred', static_values )
    rescue Configh::ConfigInitError => e
      check_errors = e.message
    end
    Armagh::Support::FTP.unstub(:ftp_validation)

    if expected_errors
      assert_equal( expected_errors, check_errors, "config errors were incorrect" ) if expected_errors
    else
      static_values.each do |grp,grp_hash|
        grp_hash.each do |pname,val|
          assert_equal val, config.send(grp.to_sym).send(pname.to_sym)
        end
      end
    end
    config
  end

  def config_good( changes =  nil )
    Armagh::Support::FTP.stubs(:ftp_validation)
    config = Armagh::Support::FTP.create_configuration( @config_store, 'cg', merge_config_values( @base_valid_config, changes ))
    Armagh::Support::FTP.unstub(:ftp_validation)
    config
  end

  def mock_ftp
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path ).returns(true)
    @mock_ftp.stubs(:putbinaryfile)
    @mock_ftp.stubs(:getbinaryfile)
    @mock_ftp.stubs(:delete)
    @mock_ftp.expects(:close)
  end

  def test_config_good
    mock_ftp
    config = assert_create_configuration_returns_config_or_errors( {}, nil )
    assert_equal( {}, config.test_and_return_errors )
  end

  def test_config_missing_host
    assert_create_configuration_returns_config_or_errors( { 'ftp' => { 'host' => nil }}, "Unable to create configuration for 'Armagh::Support::FTP' named 'fred' because: \n    Group 'ftp' Parameter 'host': type validation failed: value cannot be nil" )
  end

  def test_config_anonymous
    mock_ftp
    @mock_ftp.unstub(:login)
    @mock_ftp.expects(:login).with()
    @mock_ftp.unstub(:close)
    @mock_ftp.unstub(:chdir)
    config = assert_create_configuration_returns_config_or_errors( {'ftp' => {'anonymous' => true }}, nil)
    assert_true config.ftp.anonymous
    Armagh::Support::FTP::Connection.new(config)
  end

  def test_config_not_anonymous
    mock_ftp
    @mock_ftp.unstub(:login)
    @mock_ftp.expects(:login).with('myftpuser', 'MyFtpPassword')
    @mock_ftp.unstub(:close)
    @mock_ftp.unstub(:chdir)
    config = assert_create_configuration_returns_config_or_errors( {'ftp' => {'anonymous' => false }}, nil)
    assert_false config.ftp.anonymous
    Armagh::Support::FTP::Connection.new(config)
  end

  def test_config_missing_password
    config = assert_create_configuration_returns_config_or_errors( { 'ftp' => { 'password' => nil }}, nil)
    assert_equal({'ftp_validation' => 'Username and password must be specified when not using anonymous authentication.'}, config.test_and_return_errors)
  end

  def test_config_missing_username
    config = assert_create_configuration_returns_config_or_errors( { 'ftp' => { 'password' => nil }}, nil)
    assert_equal({'ftp_validation' => 'Username and password must be specified when not using anonymous authentication.'}, config.test_and_return_errors)
  end

  def test_config_anonymous_with_username
    config = assert_create_configuration_returns_config_or_errors( { 'ftp' => {'password' => nil, 'anonymous' => true }}, nil)
    assert_equal({'ftp_validation' => 'Ambiguous use of anonymous with username or password.'}, config.test_and_return_errors)
  end

  def test_config_anonymous_with_password
    config = assert_create_configuration_returns_config_or_errors( { 'ftp' => { 'username' => nil, 'anonymous' => true }}, nil)
    assert_equal({'ftp_validation' => 'Ambiguous use of anonymous with username or password.'}, config.test_and_return_errors)
  end

  def test_config_validation_anonymous
    config = assert_create_configuration_returns_config_or_errors( { 'ftp' => { 'username' => nil, 'password' => nil, 'anonymous' => true }}, nil)

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with().returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path ).returns(true)
    @mock_ftp.stubs(:putbinaryfile)
    @mock_ftp.stubs(:delete)
    @mock_ftp.expects(:close)

    assert_empty config.test_and_return_errors
  end

  def test_config_failed_group_test_via_test_callback

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).raises(Net::FTPPermError)

    Armagh::Support::FTP.stubs(:ftp_validation)
    config = Armagh::Support::FTP.create_configuration( @config_store, 'cfgv', @base_valid_config )
    Armagh::Support::FTP.unstub(:ftp_validation)
    
    assert_equal({'ftp_validation' => 'FTP Connection Test error: Permissions failure when logging in as myftpuser.'}, config.test_and_return_errors )
  end

  def test_config_failed_group_test_via_validation_callback

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).raises(Net::FTPPermError)

    e = Configh::ConfigInitError.new("Unable to create configuration for 'Armagh::Support::FTP' named 'cfgv' because: \n    FTP Connection Test error: Permissions failure when logging in as myftpuser.")
    assert_raise(e) { Armagh::Support::FTP.create_configuration( @config_store, 'cfgv', @base_valid_config ) }
  end

  def test_default_connect

    config = config_good

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path ).returns(true)
    @mock_ftp.expects(:close)

    assert_nothing_raised do
      Armagh::Support::FTP::Connection.open( config ) { |ftp_connection| }
    end
  end

  def test_open_socket_error

    config = config_good

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).raises(SocketError)

    e = assert_raise( Armagh::Support::FTP::ConnectionError ) do
      Armagh::Support::FTP::Connection.open( config ) { |ftp_connection| }
    end
    assert_equal "Unable to resolve host #{@test_ftp_host}", e.message
  end

  def test_open_timeout

    config = config_good

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).raises(Net::OpenTimeout)

    e = assert_raise( Armagh::Support::FTP::TimeoutError ) do
      Armagh::Support::FTP::Connection.open( config ) { |ftp_connection| }
    end
    assert_equal "Opening the connection to #{@test_ftp_host} timed out.", e.message
  end

  def test_connection_refused

    config = config_good

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).raises(Errno::ECONNREFUSED)

    e = assert_raise( Armagh::Support::FTP::ConnectionError ) do
      Armagh::Support::FTP::Connection.open( config ) { |ftp_connection| }
     end
    assert_equal "The server #{@test_ftp_host} refused the connection.", e.message
  end

  def test_auth_error

    config = config_good

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).raises(Net::FTPPermError)

    e = assert_raise( Armagh::Support::FTP::PermissionsError ) do
      Armagh::Support::FTP::Connection.open( config ) { |ftp_connection| }
    end
    assert_equal "Permissions failure when logging in as #{@test_ftp_username}.", e.message
  end

  def test_reply_error_blank_password_servers_sends_ftppermerror

    use_config = merge_config_values( @base_valid_config, { 'ftp' => { 'password' =>  Configh::DataTypes::EncodedString.from_plain_text( '' )}})

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, '' ).raises(Net::FTPPermError)

    e = Configh::ConfigInitError.new("Unable to create configuration for 'Armagh::Support::FTP' named 'rebpssf' because: \n    FTP Connection Test error: Permissions failure when logging in as myftpuser.")
    assert_raise(e) { Armagh::Support::FTP.create_configuration( @config_store, 'rebpssf', use_config ) }
  end

  def test_reply_error_blank_password_servers_sends_ftpreplyerror

    use_config = merge_config_values( @base_valid_config, { 'ftp' => { 'password' =>  Configh::DataTypes::EncodedString.from_plain_text( '' )}})

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, '').raises( Net::FTPReplyError )

    Armagh::Support::FTP.stubs(:ftp_validation)
    config = Armagh::Support::FTP.create_configuration( @config_store, 'rebpssff', use_config )
    Armagh::Support::FTP.unstub(:ftp_validation)
    assert ['FTP Connection Test error: Ambiguous FTP Reply error from server.',
            'FTP Connection Test error: FTP Reply error from server; probably not allowed to have a blank password.'
           ].include? config.test_and_return_errors[ 'ftp_validation' ]
  end

  def test_reply_error_wrong_password_servers_sends_ftpreplyerror

    use_config = merge_config_values( @base_valid_config, { 'ftp' => { 'password' =>  Configh::DataTypes::EncodedString.from_plain_text( 'badpassword' )}})

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, 'badpassword').raises( Net::FTPReplyError )

    e = Configh::ConfigInitError.new("Unable to create configuration for 'Armagh::Support::FTP' named 'rebpssff' because: \n    FTP Connection Test error: Ambiguous FTP Reply error from server.")
    assert_raise(e) { Armagh::Support::FTP.create_configuration( @config_store, 'rebpssff', use_config ) }
  end

  def test_unhandled_error

    use_config = merge_config_values( @base_valid_config, { 'ftp' => { 'password' =>  Configh::DataTypes::EncodedString.from_plain_text( 'badpassword' )}})

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).raises(StandardError, 'Some error message')

    e = Configh::ConfigInitError.new("Unable to create configuration for 'Armagh::Support::FTP' named 'rebpssff' because: \n    FTP Connection Test error: Unknown error raised on FTP connect: Some error message")
    assert_raise(e) { Armagh::Support::FTP.create_configuration( @config_store, 'rebpssff', use_config ) }
  end

  def test_reply_error_with_password

    config = config_good

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).raises(Net::FTPPermError)

    e = assert_raise( Armagh::Support::FTP::PermissionsError ) do
      Armagh::Support::FTP::Connection.open( config ) { |ftp_connection| }
    end
    assert_equal "Permissions failure when logging in as #{@test_ftp_username}.", e.message
  end

  def test_chdir

    config = config_good

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path  ).returns( true )
    @mock_ftp.expects(:chdir).with( 'test' ).returns( true )
    @mock_ftp.expects(:close)

    assert_nothing_raised do
      Armagh::Support::FTP::Connection.open( config ) do |ftp_connection|
        ftp_connection.chdir( 'test' )
      end
    end
  end

  def test_chdir_with_ftp_perm_error

    config = config_good

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.stubs(:chdir).raises(Net::FTPPermError)
    @mock_ftp.expects(:close)

    assert_raise(Armagh::Support::FTP::PermissionsError) do
      Armagh::Support::FTP::Connection.open( config ) do |ftp_connection|
        ftp_connection.chdir( 'test' )
      end
    end
  end

  def test_chdir_with_generic_error

    config = config_good

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.stubs(:chdir).raises(StandardError)
    @mock_ftp.expects(:close)

    assert_raise(Armagh::Support::FTP::UnhandledError) do
      Armagh::Support::FTP::Connection.open( config ) do |ftp_connection|
        ftp_connection.chdir( 'test' )
      end
    end
  end

  def test_get_files

    test_ftp_filename_pattern = '*.txt'
    config = config_good({'ftp' => {'maximum_transfer' => 5, 'filename_pattern' => test_ftp_filename_pattern}})

    Net::FTP.expects(:new).returns(@mock_ftp)
    @mock_ftp.expects(:connect).with(@test_ftp_host, 21)
    @mock_ftp.expects(:login).with(@test_ftp_username, @test_ftp_password.plain_text).returns(true)
    @mock_ftp.expects(:chdir).with(@test_ftp_directory_path).returns(true)
    @mock_ftp.expects(:getbinaryfile).times(5).with() {|fn| /file[12345].txt/ =~ fn}.returns(true)
    @mock_ftp.expects(:mtime).times(5).returns(Time.now)
    @mock_ftp.expects(:delete).times(5).with() {|fn| /file[12345].txt/ =~ fn}.returns(true)
    @mock_ftp.expects(:close)

    Armagh::Support::FTP::Connection.open(config) do |ftp_connection|
      ftp_connection.expects(:ls_r).returns((1..9).collect {|i| "file#{i}.txt"})
      ftp_connection.get_files do |local_filename, attributes, error_string|
        assert_not_empty local_filename
        assert_kind_of(Time, attributes['mtime'])
        assert_nil error_string
      end
    end
  end

  def test_get_files_with_read_timeout_error
    test_ftp_filename_pattern = '*.txt'
    config = config_good( { 'ftp' => { 'maximum_transfer' => 5, 'filename_pattern' => test_ftp_filename_pattern }})

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path  ).returns( true )
    @mock_ftp.stubs(:getbinaryfile).raises(Net::ReadTimeout)
    @mock_ftp.expects(:close)

    assert_raises(Armagh::Support::FTP::ConnectionError) do
      Armagh::Support::FTP::Connection.open( config ) do |ftp_connection|
        ftp_connection.expects(:ls_r).returns((1..9).collect {|i| "file#{i}.txt"})
        ftp_connection.get_files do |local_filename, attributes, error_string|
          assert_nil local_filename
          assert_empty attributes
          assert_kind_of(String, error_string)
        end
      end
    end
  end

  def test_get_files_with_generic_error
    test_ftp_filename_pattern = '*.txt'
    config = config_good( { 'ftp' => { 'maximum_transfer' => 5, 'filename_pattern' => test_ftp_filename_pattern }})

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path  ).returns( true )
    @mock_ftp.stubs(:getbinaryfile).raises(StandardError, "Some error message")
    @mock_ftp.expects(:close)

    assert_raises(Armagh::Support::FTP::ConnectionError) do
      Armagh::Support::FTP::Connection.open( config ) do |ftp_connection|
        ftp_connection.expects(:ls_r).returns((1..9).collect {|i| "file#{i}.txt"})
        ftp_connection.get_files do |local_filename, attributes, error_string|
          assert_nil local_filename
          assert_empty attributes
          assert_kind_of(String, error_string)
        end
      end
    end
  end

  def test_put_files

    config = config_good( { 'ftp' => { 'maximum_transfer' => 5, 'delete_on_put' => true }})

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path  ).returns( true )
    @mock_ftp.expects(:putbinaryfile).times(5).with(){ |fn| /file[12345].txt/ =~ fn }.returns(true)
    @mock_ftp.expects(:close)
    @mock_ftp.stubs(:mkdir)

    FakeFS do
      FileUtils.mkdir_p( '/tmp' )
      (1..9).each { |i| FileUtils.touch( "/tmp/file#{i}.txt" )}
      Dir.chdir( '/tmp' )

      put_files = []
      Armagh::Support::FTP::Connection.open( config ) do |ftp_connection|
        ftp_connection.put_files do |local_filename, error_string|
          assert_nil error_string
          put_files << local_filename
        end
      end

      assert_equal [ 'file1.txt', 'file2.txt', 'file3.txt', 'file4.txt', 'file5.txt' ], put_files
      whats_left = Dir.glob( "*.txt" ).collect{ |fn| File.basename(fn)}
      assert_equal [ 'file6.txt', 'file7.txt', 'file8.txt', 'file9.txt' ], whats_left
    end
  end

  def test_put_files_with_generic_error
    config = config_good( { 'ftp' => { 'maximum_transfer' => 5, 'delete_on_put' => true }})

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path  ).returns( true )
    @mock_ftp.stubs(:putbinaryfile).raises(StandardError, "Some error message")
    @mock_ftp.expects(:close)
    @mock_ftp.stubs(:mkdir)

    exception = nil

    FakeFS do
      FileUtils.mkdir_p( '/tmp' )
      (1..9).each { |i| FileUtils.touch( "/tmp/file#{i}.txt" )}
      Dir.chdir( '/tmp' )

      begin
        Armagh::Support::FTP::Connection.open( config ) do |ftp_connection|
          ftp_connection.put_files do |local_filename, error_string|
            assert_nil local_filename
            assert_kind_of(String, error_string)
          end
        end
      rescue => e
        exception = e
      end
    end

    assert_kind_of Armagh::Support::FTP::ConnectionError, exception
  end

  def test_write_and_delete_test_file_error

    config = config_good

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path  ).returns( true )
    @mock_ftp.stubs(:putbinaryfile).raises(Net::FTPPermError)
    @mock_ftp.expects(:close)

    e = assert_raise( Armagh::Support::FTP::PermissionsError ) do
      Armagh::Support::FTP::Connection.open( config ) { |ftp_connection|
        ftp_connection.write_and_delete_test_file
      }
    end
    assert_equal "Unable to write / delete a test file.  Verify path and permissions on the server.", e.message
  end

  def test_ls
    config = config_good
    mock_ftp
    expected = [1,2,3]

    @mock_ftp.expects(:nlst).returns expected

    Armagh::Support::FTP::Connection.open( config ) do |ftp|
      assert_equal(expected,ftp.ls)
    end
  end

  def test_directory?
    config = config_good
    mock_ftp

    @mock_ftp.expects(:size).with('dir').raises(Net::FTPPermError.new('550 Could not get file size'))
    @mock_ftp.expects(:size).with('file').returns(1024)
    Armagh::Support::FTP::Connection.open( config ) do |ftp|
      assert_true ftp.directory? 'dir'
    end

    mock_ftp
    Armagh::Support::FTP::Connection.open( config ) do |ftp|
      assert_false ftp.directory? 'file'
    end
  end

  def test_mkdir_p
    config = config_good
    mock_ftp

    @mock_ftp.expects(:mkdir).with 'some'
    @mock_ftp.expects(:mkdir).with 'some/file'
    @mock_ftp.expects(:mkdir).with 'some/file/path'

    Armagh::Support::FTP::Connection.open( config ) do |ftp|
      ftp.mkdir_p 'some/file/path'
    end
  end

  def test_rmdir
    config = config_good
    mock_ftp

    @mock_ftp.unstub(:delete)
    @mock_ftp.expects(:nlst).with('some/file/path').returns %w(some/file/path/dir some/file/path/file1 some/file/path/file2)
    @mock_ftp.expects(:nlst).with('some/file/path/dir').returns %w(some/file/path/dir/file3 some/file/path/dir/file4)

    @mock_ftp.expects(:delete).with('some/file/path/file1')
    @mock_ftp.expects(:delete).with('some/file/path/file2')
    @mock_ftp.expects(:delete).with('some/file/path/dir/file3')
    @mock_ftp.expects(:delete).with('some/file/path/dir/file4')

    @mock_ftp.expects(:rmdir).with('some/file/path/dir')
    @mock_ftp.expects(:rmdir).with('some/file/path')

    Armagh::Support::FTP::Connection.open( config ) do |ftp|
      ftp.expects(:directory?).with('some/file/path/dir').returns(true)
      ftp.expects(:directory?).with('some/file/path/file1').returns(false)
      ftp.expects(:directory?).with('some/file/path/file2').returns(false)
      ftp.expects(:directory?).with('some/file/path/dir/file3').returns(false)
      ftp.expects(:directory?).with('some/file/path/dir/file4').returns(false)

      ftp.rmdir 'some/file/path'
    end
  end

  def test_ls_r
    config = config_good
    mock_ftp

    expected = ['file_0.txt',
                'file_1.txt',
                'subdir/file 0.txt',
                'subdir/file 1.txt']
    actual = []

    @mock_ftp.expects(:nlst).with('-R something').returns(
        [
            './:',
            'file_0.txt',
            'file_1.txt',
            'subdir',
            '',
            './subdir:',
            './subdir/file 0.txt',
            './subdir/file 1.txt'
        ])

    Armagh::Support::FTP::Connection.open(config) do |ftp|
      ftp.expects(:directory?).with('file_0.txt').returns(false)
      ftp.expects(:directory?).with('file_1.txt').returns(false)

      ftp.expects(:directory?).with('subdir').returns(:true)
      ftp.expects(:directory?).with('./subdir/file 0.txt').returns(false)
      ftp.expects(:directory?).with('./subdir/file 1.txt').returns(false)

      ftp.expects(:directory).with('./:').never

      ftp.expects(:directory).with('./subdir:').never

      actual = ftp.ls_r('something')
    end

    assert_equal expected, actual
  end
end
