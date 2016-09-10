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

require_relative '../../../lib/armagh/support/ftp.rb'

class TestUnitFTPSupport < Test::Unit::TestCase

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
    begin
      config = Armagh::Support::FTP.create_configuration( @config_store, 'fred', static_values )
    rescue Configh::ConfigInitError => e
      check_errors = e.message
    end
    
    if expected_errors 
      
      assert_equal( expected_errors, check_errors, "config errors were incorrect" ) if expected_errors
      
    else
      static_values.each do |grp,grp_hash|  
        grp_hash.each do |pname,val|
          assert_equal val, config.send(grp.to_sym).send(pname.to_sym)
        end
      end
    end
  end
  
  def config_good( changes =  nil )

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path ).returns(true)
    @mock_ftp.stubs(:putbinaryfile)
    @mock_ftp.stubs(:getbinaryfile)
    @mock_ftp.stubs(:delete)
    @mock_ftp.expects(:close)

    Armagh::Support::FTP.create_configuration( @config_store, 'cg', merge_config_values( @base_valid_config, changes ))
  end
  
  def test_config_good
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path ).returns(true)
    @mock_ftp.stubs(:putbinaryfile)
    @mock_ftp.stubs(:getbinaryfile)
    @mock_ftp.stubs(:delete)
    @mock_ftp.expects(:close)

    assert_create_configuration_returns_config_or_errors( {}, nil )
  end
  
  def test_config_missing_host
    assert_create_configuration_returns_config_or_errors( { 'ftp' => { 'host' => nil }}, "Unable to create configuration Armagh::Support::FTP fred: ftp host: type validation failed: value cannot be nil" )
  end
    
  def test_config_missing_username
    assert_create_configuration_returns_config_or_errors( { 'ftp' => { 'username' => nil }}, "Unable to create configuration Armagh::Support::FTP fred: ftp username: type validation failed: value cannot be nil" )
  end
    
  def test_config_missing_password
    assert_create_configuration_returns_config_or_errors( { 'ftp' => { 'password' => nil }}, "Unable to create configuration Armagh::Support::FTP fred: ftp password: type validation failed: value cannot be nil" )
  end
   
  def test_config_failed_group_validation
    
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).raises(Net::FTPPermError)
    e = assert_raises( Configh::ConfigInitError ) { Armagh::Support::FTP.create_configuration( @config_store, 'cfgv', @base_valid_config )}
    assert_equal "Unable to create configuration Armagh::Support::FTP cfgv: FTP Connection Test error: Permissions failure when logging in as myftpuser.", e.message
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
     
    e = assert_raise( Configh::ConfigInitError ) do
      config = Armagh::Support::FTP.create_configuration( @config_store, 'rebpssf', use_config )
    end
    assert_equal "Unable to create configuration Armagh::Support::FTP rebpssf: FTP Connection Test error: Permissions failure when logging in as myftpuser.", e.message
  end
    
  def test_reply_error_blank_password_servers_sends_ftpreplyerror
    
    use_config = merge_config_values( @base_valid_config, { 'ftp' => { 'password' =>  Configh::DataTypes::EncodedString.from_plain_text( '' )}})
    
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, '').raises( Net::FTPReplyError )
     
    e = assert_raise( Configh::ConfigInitError ) do
      config = Armagh::Support::FTP.create_configuration( @config_store, 'rebpssff', use_config )
    end
    assert [ "Unable to create configuration Armagh::Support::FTP rebpssff: FTP Connection Test error: Ambiguous FTP Reply error from server.", "Unable to create configuration Armagh::Support::FTP rebpssff: FTP Connection Test error: FTP Reply error from server; probably not allowed to have a blank password." ].include? e.message
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
  
  def test_get_files
    
    test_ftp_filename_pattern = '*.txt'
    config = config_good( { 'ftp' => { 'maximum_transfer' => 5, 'filename_pattern' => test_ftp_filename_pattern }})

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path  ).returns( true )
    @mock_ftp.expects(:nlst).with( test_ftp_filename_pattern ).returns( (1..9).collect{ |i| "file#{i}.txt" } )
    @mock_ftp.expects(:getbinaryfile).times(5).with(){ |fn| /file[12345].txt/ =~ fn }.returns(true)
    @mock_ftp.expects(:delete).times(5).with(){ |fn| /file[12345].txt/ =~ fn }.returns(true)
    @mock_ftp.expects(:close)
    
    assert_nothing_raised do
      Armagh::Support::FTP::Connection.open( config ) do |ftp_connection|
        ftp_connection.get_files do |local_filename, error_string|
          assert_nil error_string
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
  

end