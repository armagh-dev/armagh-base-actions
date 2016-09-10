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
require 'mocha/test_unit'
require 'fakefs/safe'

require_relative '../../lib/armagh/support/ftp.rb'

# integration test of Armagh::Support::FTP with Net::FTP

class TestIntegrationFTPAction < Test::Unit::TestCase

  def setup
    
    local_integration_test_config ||= load_local_integration_test_config
    @test_ftp_host = local_integration_test_config[ 'test_ftp_host' ]
    @test_ftp_username = local_integration_test_config[ 'test_ftp_username' ]
    @test_ftp_password = local_integration_test_config[ 'test_ftp_password' ]
    @test_ftp_directory_path = 'readwrite_dir'

    @base_config = { 
      'ftp' => {
        'host'     => @test_ftp_host,
        'username' => @test_ftp_username, 
        'password' => @test_ftp_password,
        'directory_path' => @test_ftp_directory_path
      }
    }
    
    @config_store = []
 
  end
  
  def load_local_integration_test_config
    
    config = nil
    config_filepath = File.join( __dir__, 'local_integration_test_config.json' )
    
    begin
      
      config = JSON.load( File.read( config_filepath ))
      errors = []
      if config.is_a? Hash
        [ 'test_ftp_username', 'test_ftp_password', 'test_ftp_host' ].each do |k|
          errors << "Config file missing member #{k}" unless config.has_key?( k )
        end
      else
        errors << "Config file should contain a hash of test_ftp_username, test_ftp_password (Base64 encoded), and test_ftp_host"
      end
      
      if errors.empty?
        config[ 'test_ftp_password' ] = Configh::DataTypes::EncodedString.from_encoded( config[ 'test_ftp_password' ])
        
      else
        raise errors.join("\n")
    
      end
      
    rescue => e
      
      puts "Integration test environment not set up.  See test/integration/ftp_test.readme.  Detail: #{ e.message }"
      pend
      
    end
    config
  end
  

  def test_successful_test
    
    assert_nothing_raised do
      Armagh::Support::FTP.create_configuration( @config_store, 'success', @base_config )
    end
  end
 
  def test_fail_test_bad_domain
    
    @base_config[ 'ftp'][ 'host' ] = "idontexist.kurmudgeon.edd"
    
    e = assert_raises( Configh::ConfigInitError ) do
      Armagh::Support::FTP.create_configuration( @config_store, 'baddom', @base_config )
    end
    assert_equal "Unable to create configuration Armagh::Support::FTP baddom: FTP Connection Test error: Unable to resolve host idontexist.kurmudgeon.edd", e.message
  end
  
  def test_fail_test_bad_host
    
    @base_config[ 'ftp' ][ 'host' ] = "idontexist.kurmudgeon.edu"
    
    e = assert_raises( Configh::ConfigInitError ) do
      Armagh::Support::FTP.create_configuration( @config_store, 'badhost', @base_config )
    end
    assert_equal "Unable to create configuration Armagh::Support::FTP badhost: FTP Connection Test error: Unable to resolve host idontexist.kurmudgeon.edu", e.message
  end

  def test_fail_test_nonexistent_user
    
    @base_config[ 'ftp'][ 'username' ] = "idontexisteither"
    
    e = assert_raises( Configh::ConfigInitError ) do
      Armagh::Support::FTP.create_configuration( @config_store, 'nonexuser', @base_config )
    end
    assert_equal "Unable to create configuration Armagh::Support::FTP nonexuser: FTP Connection Test error: Permissions failure when logging in as idontexisteither.", e.message
  end

  def test_fail_test_wrong_password
    
    @base_config[ 'ftp' ][ 'password' ] = Configh::DataTypes::EncodedString.from_plain_text "NotMyPassword"
    
    e = assert_raises( Configh::ConfigInitError ) do
      Armagh::Support::FTP.create_configuration( @config_store, 'wrongpass', @base_config )
    end
    assert_equal "Unable to create configuration Armagh::Support::FTP wrongpass: FTP Connection Test error: Permissions failure when logging in as ftptest.", e.message
  end

  def test_fail_test_blank_password
    
    @base_config[ 'ftp' ][ 'password' ] = Configh::DataTypes::EncodedString.from_plain_text "NotMyPassword"
    
    e = assert_raises( Configh::ConfigInitError ) do
      Armagh::Support::FTP.create_configuration( @config_store, 'blankpass', @base_config )
    end
    
    assert_true [ "Unable to create configuration Armagh::Support::FTP blankpass: FTP Connection Test error: Permissions failure when logging in as ftptest.",
                  "Unable to create configuration Armagh::Support::FTP blankpass: FTP Connection Test error: FTP Reply error from server; probably not allowed to have a blank password." 
                ].include? e.message
  end
  
  def test_fail_test_noexistent_directory
    
    @base_config[ 'ftp' ][ 'directory_path' ] = "no_such_dir"

    e = assert_raises( Configh::ConfigInitError ) do
      Armagh::Support::FTP.create_configuration( @config_store, 'nonexdir', @base_config )
    end
    assert_equal "Unable to create configuration Armagh::Support::FTP nonexdir: FTP Connection Test error: User does not have access to directory no_such_dir.", e.message
  end    
    
  def test_fail_test_readonly_directory
    
    @base_config[ 'ftp' ][ 'directory_path' ] = "read_only_dir"
    
    e = assert_raises( Configh::ConfigInitError ) do
      Armagh::Support::FTP.create_configuration( @config_store, 'rodir', @base_config )
    end
    assert_equal "Unable to create configuration Armagh::Support::FTP rodir: FTP Connection Test error: Unable to write / delete a test file.  Verify path and permissions on the server.", e.message
  end    
 
  def test_put_then_get_files
    
    @base_config[ 'ftp' ][ 'maximum_transfer' ] = 5
    @base_config[ 'ftp' ][ 'filename_pattern' ] = '*.txt' 
    @base_config[ 'ftp' ][ 'delete_on_put' ] = true
    config = Armagh::Support::FTP.create_configuration( @config_store, 'putthenget', @base_config )
    
    FakeFS do
      
      test_file_list = (1..5).collect{ |i| "test#{i}.txt" }
      test_file_list.each { |fn| File.open(fn,"w") << "I am file #{fn}.\n"}
      
      put_files = []
      assert_nothing_raised do
        Armagh::Support::FTP::Connection.open( config ) do |ftp_connection|
          
          ftp_connection.put_files do |filename,error_string|
            assert_nil error_string
            put_files << filename
          end
          
          assert_equal test_file_list, put_files
          assert Dir.glob( "test*.txt" ).empty?
      
        end
      end
    
      assert_nothing_raised do
        Armagh::Support::FTP::Connection.open( config ) do |ftp_connection|
          
          ftp_connection.get_files do |local_filename,error_string|
            assert_nil error_string
          end
          
          assert_equal test_file_list, Dir.glob("*.txt").collect{ |fn| File.basename(fn)}
        end
      end
    end
  end
end
    
