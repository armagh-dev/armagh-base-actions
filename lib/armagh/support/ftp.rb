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

require 'net/ftp'
require 'tempfile'
require 'configh'

module Armagh
  module Support
    module FTP
      include Configh::Configurable
    
      class ConnectionError     < StandardError; end
      class PermissionsError    < StandardError; end
      class ReplyError          < StandardError; end
      class TimeoutError        < StandardError; end
      class UnhandledError      < StandardError; end
        
      define_parameter name: "host",             description: "FTP host or IP",                          type: 'populated_string', required: true,  prompt: "host.example.com or 10.0.0.1"                
      define_parameter name: "port",             description: "FTP port",                                type: 'positive_integer', required: true,  default: 21                                
      define_parameter name: "directory_path",   description: "FTP base directory path",                 type: 'populated_string', required: true,  default: './'
      define_parameter name: "filename_pattern", description: "Linux file pattern",                      type: 'string',           required: false, prompt:  "*.pdf"
      define_parameter name: "username",         description: "FTP user name",                           type: 'populated_string', required: true,  prompt:  "user"
      define_parameter name: "password",         description: "FTP user password",                       type: 'encoded_string',   required: true,  prompt:  'password'
      define_parameter name: "passive_mode",     description: "FTP passive mode",                        type: 'boolean',          required: true,  default: true
      define_parameter name: "maximum_transfer", description: 'Maximum num to collect',                  type: 'positive_integer', required: true,  default: 50
      define_parameter name: "open_timeout",     description: "Timeout (secs) opening a new connection", type: 'positive_integer', required: true,  default: 30
      define_parameter name: "read_timeout",     description: "Timeout (secs) reading on a connection",  type: 'positive_integer', required: true,  default: 60
      define_parameter name: "delete_on_put",    description: "Delete each file put to the remote",      type: 'boolean',          required: true,  default: false
 
      define_group_validation_callback callback_class: Armagh::Support::FTP, callback_method: :test_connection
      
      def FTP.test_connection( config )
        
        error_string = nil
        begin
          Connection.test( config )
        rescue => e
          error_string = "FTP Connection Test error: #{ e.message }"
        end
        
        error_string
      end
        
      class Connection 
    
        def self.open( config )
       
          begin
            ftp_connection = new( config )
            ftp_connection.chdir config.ftp.directory_path
            yield ftp_connection
    
          ensure
            ftp_connection.close if ftp_connection
          end
        end
        
        def self.test( config )
    
          open( config ) do |ftp_connection|
    
            ftp_connection.write_and_delete_test_file
      
          end
        end
    
    
        def initialize( config )

          @config = config
          
          @priv_ftp = Net::FTP.new
          @priv_ftp.passive      = @config.ftp.passive_mode
          @priv_ftp.open_timeout = @config.ftp.open_timeout
          @priv_ftp.read_timeout = @config.ftp.read_timeout
          @priv_ftp.connect( @config.ftp.host, @config.ftp.port )
          @priv_ftp.login( @config.ftp.username, @config.ftp.password.plain_text )
      
          rescue SocketError => e
            raise ConnectionError, "Unable to resolve host #{ @config.ftp.host }"
        
          rescue Net::OpenTimeout => e
            raise TimeoutError, "Opening the connection to #{ @config.ftp.host } timed out."
  
          rescue Errno::ECONNREFUSED => e
            raise ConnectionError, "The server #{ @config.ftp.host } refused the connection."
                 
          rescue Net::FTPPermError => e
            raise PermissionsError, "Permissions failure when logging in as #{ @config.ftp.username }."
  
          rescue Net::FTPReplyError => e
            if @config.ftp.password == ""
              raise ReplyError, "FTP Reply error from server; probably not allowed to have a blank password."
            else
              raise ReplyError, "Ambiguous FTP Reply error from server."
            end

          rescue => e
            raise UnhandledError, "Unknown error raised on FTP connect: #{e.message}"
      
        end
    
        def close
          @priv_ftp.close
        end
  
        def chdir( dir )
    
          @priv_ftp.chdir( dir )
      
          rescue Net::FTPPermError => e
            raise PermissionsError, "User does not have access to directory #{ dir }."
      
          rescue => e  
            raise UnhandledError, "Unexpected FTP error when changing directory to #{ dir }: #{ e.message }"
            
        end
  
        def get_files
    
          remote_files = @priv_ftp.nlst( @config.ftp.filename_pattern )
          files_to_transfer = remote_files.first( @config.ftp.maximum_transfer )
          failed_files = 0
      
          files_to_transfer.each do |remote_filename|
        
            attempts_this_file = 0
            
            begin
              attempts_this_file += 1
              @priv_ftp.getbinaryfile remote_filename
              yield File.basename( remote_filename ), nil
              @priv_ftp.delete( remote_filename )
              failed_files = 0
      
            rescue Net::ReadTimeout
              retry unless attempts_this_file >= 3
              yield nil, "Timed out trying to read file #{ remote_filename }."
              failed_files += 1
              raise ConnectionError, "Three files in a row failed.  Aborting." if failed_files == 3
            
            rescue => e
              retry unless attempts_this_file >= 3
              yield nil, "Unhandled error in getting files: #{ e.message }.\nBacktrace: #{ e.backtrace.join("\n")}"
              failed_files += 1
              raise ConnectionError, "Three file in a row failed. Aborting." if failed_files == 3
            end
          end
      
        end


        def put_files
    
          local_files = Dir.glob( @config.ftp.filename_pattern || "*" )
          files_to_transfer = local_files.first( @config.ftp.maximum_transfer )
          failed_files = 0
  
          files_to_transfer.each do |local_filename|
    
            attempts_this_file = 0
            
            begin
              attempts_this_file += 1
              @priv_ftp.putbinaryfile local_filename
              yield File.basename(local_filename), nil
              File.delete( local_filename ) if ( @config.ftp.delete_on_put and File.exists?( local_filename ))
              failed_files = 0
  
            rescue => e
              retry unless attempts_this_file >= 3
              yield nil, "Unhandled error in putting files via FTP: #{ e.message }.\nBacktrace: #{ e.backtrace.join("\n")}"
              failed_files += 1
              raise ConnectionError, "Three files in a row failed.  Aborting." if failed_files == 3
            end
          end
    
        end
  
        def write_and_delete_test_file
      
          test_filename = "xyzzy_armagh_test_#{Time.now.to_i}"
          test_file = Tempfile.new test_filename
          test_file.write "This is test content"
          test_file.close
      
          @priv_ftp.putbinaryfile test_file.path
          sleep 5
          @priv_ftp.delete File.basename(test_file.path)
      
          rescue Net::FTPPermError => e
            raise PermissionsError, "Unable to write / delete a test file.  Verify path and permissions on the server."
          ensure
            test_file.unlink
        
        end
      end
    end
      
  end
end