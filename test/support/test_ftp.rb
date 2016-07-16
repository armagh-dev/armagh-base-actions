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


require_relative '../coverage_helper'

require 'test/unit'
require 'mocha/test_unit'
require 'fakefs/safe'

require_relative '../../lib/armagh/actions/collect.rb'
require_relative '../../lib/armagh/actions/consume.rb'
require_relative '../../lib/armagh/support/ftp.rb'

module Armagh
  module Actions
    
    class FakeCollectMocked < Collect
      extend Armagh::Support::FTP
    end

    class FakeConsumeMocked < Consume
      extend Armagh::Support::FTP
    end
  end
end


class TestUnitFTPAction < Test::Unit::TestCase

  def setup
    
    @logger = mock
    @caller = mock
    @config_defaults = Armagh::Actions::FakeCollectMocked.defined_parameter_defaults
    
    @test_ftp_host = 'testserver'
    @test_ftp_username = 'myftpuser'
    @test_ftp_password = EncodedString.from_plain_text( 'MyFtpPassword' )
    @test_ftp_directory_path = 'readable_test_dir'
    @base_config = @config_defaults.merge( { 
      'ftp_host'     => @test_ftp_host,
      'ftp_username' => @test_ftp_username, 
      'ftp_password' => @test_ftp_password,
      'ftp_directory_path' => @test_ftp_directory_path,
    })
    @output_docspec = Armagh::Documents::DocSpec.new('OutputDocument', Armagh::Documents::DocState::READY)
    @docspec_config = { 'output_type' => @output_docspec }
    
    @mock_ftp = mock('Ftp server')
    @mock_ftp.stubs(:passive=)
    @mock_ftp.stubs(:open_timeout=)
    @mock_ftp.stubs(:read_timeout=)

  end
    
  def create_action_and_confirm_validate_returns_errors_warnings( missing_params, changed_params, expected_errors, expected_warnings )
    use_configs = @base_config
    use_configs.delete_if{ |k,v| missing_params.include? k }
    use_configs = use_configs.merge( changed_params )

    fake_collect_action = Armagh::Actions::FakeCollectMocked.new( 'action', @caller, @logger, use_configs, @docspec_config )
    validate_result = fake_collect_action.validate
    assert_equal expected_errors.empty?, validate_result[ 'valid' ], "valid wrong"
    assert_equal expected_errors, validate_result[ 'errors' ], "errors wrong"
    assert_equal expected_warnings, validate_result[ 'warnings' ], "warnings wrong"
  end
  
  def test_validate_good_configuration

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path ).returns(true)
    @mock_ftp.stubs(:putbinaryfile)
    @mock_ftp.stubs(:getbinaryfile)
    @mock_ftp.stubs(:delete)
    @mock_ftp.expects(:close)

    @fake_collect_action = Armagh::Actions::FakeCollectMocked.new('action', @caller, @logger, @base_config, @docspec_config)
    assert_true @fake_collect_action.validate[ 'valid' ]
  end
  
  def test_missing_host
    create_action_and_confirm_validate_returns_errors_warnings( 
      [ 'ftp_host'], 
      {},
      [ "Required parameter 'ftp_host' is missing." ],
      []
    )
  end
    
  def test_missing_username
    create_action_and_confirm_validate_returns_errors_warnings( 
      [ 'ftp_username'], 
      {},
      [ "Required parameter 'ftp_username' is missing." ],
      []
    )
  end
    
  def test_missing_password
    create_action_and_confirm_validate_returns_errors_warnings( 
      [ 'ftp_password'], 
      {},
      [ "Required parameter 'ftp_password' is missing." ],
      []
    )
  end
   
  def test_failed_custom_validation
    
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).raises(Net::FTPPermError)

    @fake_collect_action = Armagh::Actions::FakeCollectMocked.new('action', @caller, @logger, @base_config, @docspec_config) 
    validation_results = @fake_collect_action.validate
    assert_false validation_results[ 'valid' ]
  end   
 
        
  def test_default_connect
    
    
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path ).returns(true)
    @mock_ftp.expects(:close)
    
    @fake_collect_action = Armagh::Actions::FakeCollectMocked.new('action', @caller, @logger, @base_config, @docspec_config) 
    action_params = @fake_collect_action.parameters
    
    assert_nothing_raised do
      Armagh::Support::FTP::Connection.open( action_params ) { |ftp_connection| }
    end
  end   
  
  def test_open_timeout
    
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).raises(Net::OpenTimeout)
    
    @fake_collect_action = Armagh::Actions::FakeCollectMocked.new('action', @caller, @logger, @base_config, @docspec_config)
    action_params = @fake_collect_action.parameters

    e = assert_raise( Armagh::Support::FTP::TimeoutError ) do
      Armagh::Support::FTP::Connection.open( action_params ) { |ftp_connection| }
    end
    assert_equal "Opening the connection to #{@test_ftp_host} timed out.", e.message
  end

  def test_connection_refused
    
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).raises(Errno::ECONNREFUSED)

    @fake_collect_action = Armagh::Actions::FakeCollectMocked.new('action', @caller, @logger, @base_config, @docspec_config)
    action_params = @fake_collect_action.parameters

    e = assert_raise( Armagh::Support::FTP::ConnectionError ) do
      Armagh::Support::FTP::Connection.open( action_params ) { |ftp_connection| }
     end
    assert_equal "The server #{@test_ftp_host} refused the connection.", e.message
  end
  
  def test_auth_error
    
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).raises(Net::FTPPermError)
    
    @fake_collect_action = Armagh::Actions::FakeCollectMocked.new('action', @caller, @logger, @base_config, @docspec_config)
    action_params = @fake_collect_action.parameters

    e = assert_raise( Armagh::Support::FTP::PermissionsError ) do
      Armagh::Support::FTP::Connection.open( action_params ) { |ftp_connection| }
    end
    assert_equal "Permissions failure when logging in as #{@test_ftp_username}.", e.message
  end

  def test_reply_error_blank_password_servers_sends_ftppermerror
    
    @base_config[ 'ftp_password' ] = EncodedString.from_plain_text( '' )
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, '' ).raises(Net::FTPPermError)
     
    @fake_collect_action = Armagh::Actions::FakeCollectMocked.new('action', @caller, @logger, @base_config, @docspec_config)
    action_params = @fake_collect_action.parameters

    e = assert_raise( Armagh::Support::FTP::PermissionsError ) do
      Armagh::Support::FTP::Connection.open( action_params ) { |ftp_connection| }
    end
    assert_equal "Permissions failure when logging in as #{@test_ftp_username}.", e.message
  end
    
  def test_reply_error_blank_password_servers_sends_ftpreplyerror
    
    @base_config[ 'ftp_password' ] = EncodedString.from_plain_text( '' )
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, '').raises( Net::FTPReplyError)
     
    @fake_collect_action = Armagh::Actions::FakeCollectMocked.new('action', @caller, @logger, @base_config, @docspec_config)
    action_params = @fake_collect_action.parameters

    e = assert_raise( Armagh::Support::FTP::ReplyError ) do
      Armagh::Support::FTP::Connection.open( action_params ) { |ftp_connection| }
    end
    assert_equal "FTP Reply error from server; probably not allowed to have a blank password.", e.message
  end
 
  def test_reply_error_with_password
    
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).raises(Net::FTPPermError)
    
    @fake_collect_action = Armagh::Actions::FakeCollectMocked.new('action', @caller, @logger, @base_config, @docspec_config)
    action_params = @fake_collect_action.parameters

    e = assert_raise( Armagh::Support::FTP::PermissionsError ) do
      Armagh::Support::FTP::Connection.open( action_params ) { |ftp_connection| }
    end
    assert_equal "Permissions failure when logging in as #{@test_ftp_username}.", e.message
  end
  
  def test_chdir
    
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path  ).returns( true )
    @mock_ftp.expects(:chdir).with( 'test' ).returns( true )
    @mock_ftp.expects(:close)

    @fake_collect_action = Armagh::Actions::FakeCollectMocked.new('action', @caller, @logger, @base_config, @docspec_config)
    action_params = @fake_collect_action.parameters

    assert_nothing_raised do
      Armagh::Support::FTP::Connection.open( action_params ) do |ftp_connection| 
        ftp_connection.chdir( 'test' )
      end
    end
  end
  
  def test_get_files
    
    test_ftp_filename_pattern = '*.txt'

    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path  ).returns( true )
    @mock_ftp.expects(:nlst).with( test_ftp_filename_pattern ).returns( (1..9).collect{ |i| "file#{i}.txt" } )
    @mock_ftp.expects(:getbinaryfile).times(5).with(){ |fn| /file[12345].txt/ =~ fn }.returns(true)
    @mock_ftp.expects(:delete).times(5).with(){ |fn| /file[12345].txt/ =~ fn }.returns(true)
    @mock_ftp.expects(:close)

    @base_config[ 'ftp_maximum_number_to_transfer' ] = 5
    @base_config[ 'ftp_filename_pattern' ] = test_ftp_filename_pattern 
    @fake_collect_action = Armagh::Actions::FakeCollectMocked.new( 'action', @caller, @logger, @base_config, @docspec_config )
    action_params = @fake_collect_action.parameters
    
    assert_nothing_raised do
      Armagh::Support::FTP::Connection.open( action_params ) do |ftp_connection|
        ftp_connection.get_files do |local_filename, error_string|
          assert_nil error_string
        end
      end
    end
  end
  
  def test_put_files
    
    Net::FTP.expects(:new).returns( @mock_ftp )
    @mock_ftp.expects(:connect).with( @test_ftp_host, 21 )
    @mock_ftp.expects(:login).with( @test_ftp_username, @test_ftp_password.plain_text ).returns(true)
    @mock_ftp.expects(:chdir).with( @test_ftp_directory_path  ).returns( true )
    @mock_ftp.expects(:putbinaryfile).times(5).with(){ |fn| /file[12345].txt/ =~ fn }.returns(true)
    @mock_ftp.expects(:close)

    @base_config[ 'ftp_maximum_number_to_transfer' ] = 5
    @base_config[ 'ftp_delete_on_put' ] = true
    @fake_consume_action = Armagh::Actions::FakeConsumeMocked.new( 'action', @caller, @logger, @base_config, @docspec_config )
    action_params = @fake_consume_action.parameters
    
    FakeFS do
      FileUtils.mkdir_p( '/tmp' )
      (1..9).each { |i| FileUtils.touch( "/tmp/file#{i}.txt" )}
      Dir.chdir( '/tmp' )
    
      put_files = []
      Armagh::Support::FTP::Connection.open( action_params ) do |ftp_connection|
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