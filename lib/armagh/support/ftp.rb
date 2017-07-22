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

require 'net/ftp'
require 'tempfile'
require 'configh'
require_relative '../base/errors/armagh_error'

module Armagh
  module Support
    module FTP
      include Configh::Configurable

      class FTPError         < ArmaghError; notifies :ops; end
      class ConnectionError  < FTPError;    end
      class PermissionsError < FTPError;    end
      class ReplyError       < FTPError;    end
      class TimeoutError     < FTPError;    end
      class UnhandledError   < FTPError;    end

      define_parameter name: "host",             description: "FTP host or IP",                          type: 'populated_string', required: true,  prompt: "host.example.com or 10.0.0.1"
      define_parameter name: "port",             description: "FTP port",                                type: 'positive_integer', required: true,  default: 21
      define_parameter name: "directory_path",   description: "FTP base directory path",                 type: 'populated_string', required: true,  default: './'
      define_parameter name: "filename_pattern", description: "Linux file pattern",                      type: 'string',           required: false, prompt:  "*.pdf"
      define_parameter name: "anonymous",        description: "Accesss the FTP server anonymously",      type: 'boolean',          required: true,  default: false
      define_parameter name: "username",         description: "FTP user name",                           type: 'populated_string', required: false, prompt:  'user '
      define_parameter name: "password",         description: "FTP user password",                       type: 'encoded_string',   required: false, prompt:  'password'
      define_parameter name: "passive_mode",     description: "FTP passive mode",                        type: 'boolean',          required: true,  default: true
      define_parameter name: "maximum_transfer", description: 'Maximum num to collect',                  type: 'positive_integer', required: true,  default: 50
      define_parameter name: "open_timeout",     description: "Timeout (secs) opening a new connection", type: 'positive_integer', required: true,  default: 30
      define_parameter name: "read_timeout",     description: "Timeout (secs) reading on a connection",  type: 'positive_integer', required: true,  default: 60
      define_parameter name: "delete_on_put",    description: "Delete each file put to the remote",      type: 'boolean',          required: true,  default: false

      define_group_test_callback callback_class: Armagh::Support::FTP, callback_method: :ftp_validation
      define_group_validation_callback callback_class: Armagh::Support::FTP, callback_method: :ftp_validation

      def FTP.ftp_validation(config)
        error_string = nil

        if config.ftp.anonymous
          error_string ||= 'Ambiguous use of anonymous with username or password.' if config.ftp.username || config.ftp.password
        else
          error_string ||= 'Username and password must be specified when not using anonymous authentication.' unless config.ftp.username && config.ftp.password
        end

        error_string ||= test_connection(config)
        error_string
      end

      def self.test_connection( config )

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

          if @config.ftp.anonymous
            @priv_ftp.login
          else
            @priv_ftp.login( @config.ftp.username, @config.ftp.password.plain_text )
          end

          rescue SocketError
            raise ConnectionError, "Unable to resolve host #{ @config.ftp.host }"

          rescue Net::OpenTimeout
            raise TimeoutError, "Opening the connection to #{ @config.ftp.host } timed out."

          rescue Errno::ECONNREFUSED
            raise ConnectionError, "The server #{ @config.ftp.host } refused the connection."

          rescue Net::FTPPermError
            raise PermissionsError, "Permissions failure when logging in as #{ @config.ftp.username }."

          rescue Net::FTPReplyError
            if @config.ftp.password == ''
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
          all_files = ls_r
          remote_files = []

          all_files.each do |fname|
            remote_files << fname if File.fnmatch?(@config.ftp.filename_pattern, fname)
          end

          files_to_transfer = remote_files.first( @config.ftp.maximum_transfer )
          failed_files = 0

          files_to_transfer.each do |remote_filename|

            attempts_this_file = 0
            attributes = {}

            begin
              attempts_this_file += 1
              FileUtils.mkdir_p File.dirname(remote_filename)
              @priv_ftp.getbinaryfile(remote_filename, remote_filename)

              attributes['mtime'] = @priv_ftp.mtime remote_filename
              yield remote_filename, attributes, nil
              @priv_ftp.delete( remote_filename )
              failed_files = 0

            rescue Net::ReadTimeout => e
              retry unless attempts_this_file >= 3
              yield nil, attributes, "Timed out trying to read file #{ remote_filename }."
              failed_files += 1
              raise ConnectionError, 'Three files in a row failed.  Aborting.' if failed_files == 3

            rescue => e
              retry unless attempts_this_file >= 3
              yield nil, attributes, "Unhandled error in getting files: #{ e.message }.\nBacktrace: #{ e.backtrace.join("\n")}"
              failed_files += 1
              raise ConnectionError, 'Three files in a row failed. Aborting.' if failed_files == 3
            end
          end

        end

        def put_files
          local_files = Dir.glob(@config.ftp.filename_pattern || "*")
          files_to_transfer = local_files.first(@config.ftp.maximum_transfer)
          failed_files = 0

          files_to_transfer.each do |local_filename|
            local_filename.sub!(/^\//,'')
            attempts_this_file = 0

            begin
              attempts_this_file += 1
              mkdir_p File.dirname(local_filename)
              @priv_ftp.putbinaryfile(local_filename, local_filename)

              yield local_filename, nil
              File.delete(local_filename) if (@config.ftp.delete_on_put and File.exists?(local_filename))
              failed_files = 0

            rescue => e
              retry unless attempts_this_file >= 3
              yield nil, "Unhandled error in putting files via FTP: #{ e.message }.\nBacktrace: #{ e.backtrace.join("\n")}"
              failed_files += 1
              raise ConnectionError, 'Three files in a row failed.  Aborting.' if failed_files == 3
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

        def ls(dir=nil)
          @priv_ftp.nlst(dir)
        end

        def ls_r(path = nil)
          all_remote_files = []
          args = "-R #{path}".strip

          items = @priv_ftp.nlst(args)
          items.each_with_index do |item, idx|
            all_remote_files << item.sub(/^\.\//, '') unless item.empty? || item.end_with?(':') && (idx == 0 || items[idx-1].empty?) || directory?(item)
          end

          all_remote_files
        end

        def mkdir_p(dir)
          Pathname.new(dir).descend do |path|
            path = path.to_s
            begin
              @priv_ftp.mkdir(path)
            rescue Net::FTPPermError =>  e
              if e.message.include? 'Create directory operation failed'
                next
              end
            end
          end
        end

        def rmdir(dir)
          @priv_ftp.nlst(dir).each do |item|
            directory?(item) ? rmdir(item) : @priv_ftp.delete(item)
          end
          @priv_ftp.rmdir(dir)
        end

        def directory?(path)
          dir = false
          begin
            @priv_ftp.size path
          rescue Net::FTPPermError => e
            dir = e.message.include? '550 Could not get file size'
          end
          dir
        end
      end
    end

  end
end
