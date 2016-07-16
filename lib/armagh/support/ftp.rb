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
require_relative "../actions/validations.rb"
require_relative "../actions/parameter_definitions.rb"

module Armagh
  module Support
    module FTP
    
      class ConnectionError     < StandardError; end
      class PermissionsError    < StandardError; end
      class ReplyError          < StandardError; end
      class TimeoutError        < StandardError; end
      class UnhandledError      < StandardError; end
      
      def self.extended( base )
        
        base.define_parameter name:        "ftp_host", 
                              description: "FTP host or IP", 
                              type:        String, 
                              required:    true, 
                              prompt:      "host.example.com or 10.0.0.1"
                              
        base.define_parameter name:        "ftp_port",
                              description: "FTP port",
                              type:        Integer,
                              required:    true,
                              default:     21
                                            
        base.define_parameter name:        "ftp_directory_path",
                              description: "FTP base directory path",
                              type:        String,
                              required:    true,
                              default:     '/'
    
        base.define_parameter name:        "ftp_filename_pattern",
                              description: "Linux file pattern",
                              type:        String,
                              required:    false,
                              prompt:      "*.pdf"
    
        base.define_parameter name:        "ftp_username",
                              description: "FTP user name",
                              type:        String,
                              required:    true,
                              prompt:      "user"
    
        base.define_parameter name:        "ftp_password",
                              description: "FTP user password",
                              type:        EncodedString,
                              required:    true,
                              prompt:      "password"
    
        base.define_parameter name:        "ftp_passive_mode",
                              description: "FTP passive mode (false for active mode)",
                              type:        Boolean,
                              default:     true,
                              required:    true
    
        base.define_parameter name:        "ftp_maximum_number_to_transfer",
                              description: "Max documents matching filter to collect or put in one run",
                              type:        Integer,
                              default:     50,
                              required:    true
    
        base.define_parameter name:        "ftp_open_timeout",
                              description: "Timeout (seconds) when opening a new connection",
                              type:        Integer,
                              default:     30,
                              required:    true
                     
        base.define_parameter name:        "ftp_read_timeout",
                              description: "Timeout (seconds) when reading a block on a connection",
                              type:        Integer,
                              default:     60,
                              required:    true
                            
        base.define_parameter name:        "ftp_delete_on_put",
                              description: "Deletes each file put to the remote server",
                              type:        Boolean,
                              default:     false,
                              required:    true
                              
        base.include InstanceMethods
      end
      
      module InstanceMethods
        def custom_validation
        
          superclass_custom_validations = super  # needing this could cause problems later.
        
          begin
            Connection.test( @parameters )
          rescue => e
            test_error_string = "FTP Connection Test error: #{ e.message }"
            return [ superclass_custom_validations, test_error_string ].compact.join(", ")
          end
        
          superclass_custom_validations
        
        end
      end
        
      class Connection 
    
        def self.open( params )
       
          begin
            ftp_connection = new( params )
            ftp_connection.chdir params['ftp_directory_path' ]
            yield ftp_connection
    
          ensure
            ftp_connection.close if ftp_connection
          end
        end
        
        def self.test( params )
    
          open( params ) do |ftp_connection|
    
            ftp_connection.write_and_delete_test_file
      
          end
        end
    
    
        def initialize( p )
      
          password = p['ftp_password'].plain_text
      
          @priv_ftp = Net::FTP.new
          @priv_ftp.passive = p['ftp_passive_mode'] 
          @priv_ftp.open_timeout = p['ftp_open_timeout']
          @priv_ftp.read_timeout = p['ftp_read_timeout']
          @priv_ftp.connect( p['ftp_host'], p['ftp_port'])
          @priv_ftp.login( p['ftp_username'], password )
      
          @filename_pattern = p['ftp_filename_pattern']
          @maximum_number_to_transfer = p['ftp_maximum_number_to_transfer']
          @delete_on_put = p['ftp_delete_on_put']

          rescue SocketError => e
            raise ConnectionError, "Unable to resolve host #{p['ftp_host']}"
        
          rescue Net::OpenTimeout => e
            raise TimeoutError, "Opening the connection to #{ p['ftp_host'] } timed out."
  
          rescue Errno::ECONNREFUSED => e
            raise ConnectionError, "The server #{p['ftp_host']} refused the connection."
                 
          rescue Net::FTPPermError => e
            raise PermissionsError, "Permissions failure when logging in as #{ p['ftp_username'] }."
  
          rescue Net::FTPReplyError => e
            if password == "" 
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
    
          remote_files = @priv_ftp.nlst( @filename_pattern )
          files_to_transfer = remote_files.first( @maximum_number_to_transfer )
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
    
          local_files = Dir.glob( @filename_pattern || "*" )
          files_to_transfer = local_files.first( @maximum_number_to_transfer )
          failed_files = 0
  
          files_to_transfer.each do |local_filename|
    
            attempts_this_file = 0
            
            begin
              attempts_this_file += 1
              @priv_ftp.putbinaryfile local_filename
              yield File.basename(local_filename), nil
              File.delete( local_filename ) if ( @delete_on_put and File.exists?( local_filename ))
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