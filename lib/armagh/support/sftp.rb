# Copyright 2016 Noragh Analytics, Inc.
#
# Licensed under the Apache License, Version 2.0. (the "License");
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

require 'net/sftp'
require 'fileutils'
require 'pathname'
require 'tempfile'

require_relative '../actions/validations.rb'
require_relative '../actions/parameter_definitions.rb'

module Armagh
  module Support
    module SFTP
      extend Armagh::Actions::ParameterDefinitions

      class SFTPError < StandardError;
      end
      class ConnectionError < SFTPError;
      end
      class PermissionError < SFTPError;
      end
      class FileError < SFTPError;
      end
      class TimeoutError < SFTPError;
      end

      define_parameter name: 'sftp_host',
                       description: 'SFTP host or IP',
                       type: String,
                       required: true,
                       prompt: 'host.example.com or 10.0.0.1'

      define_parameter name: 'sftp_port',
                       description: 'SFTP port',
                       type: Integer,
                       required: true,
                       default: 22

      define_parameter name: 'sftp_directory_path',
                       description: 'SFTP base directory path',
                       type: String,
                       required: true,
                       default: './'

      define_parameter name: 'sftp_filename_pattern',
                       description: 'Glob file pattern',
                       type: String,
                       required: false,
                       prompt: '*.pdf'

      define_parameter name: 'sftp_username',
                       description: 'SFTP user name',
                       type: String,
                       required: true,
                       prompt: 'user'

      define_parameter name: 'sftp_password',
                       description: 'SFTP user password',
                       type: EncodedString,
                       required: false,
                       prompt: 'password'


      define_parameter name: 'sftp_key',
                       description: 'SSH Key for SFTP connection',
                       type: String,
                       required: false,
                       prompt: 'password'

      define_parameter name: 'sftp_maximum_number_to_transfer',
                       description: 'Max documents matching filter to collect or put in one run',
                       type: Integer,
                       default: 50,
                       required: true

      def custom_validation
        Connection.open(@parameters) do |sftp|
          return sftp.test_connection
        end
      end

      class Connection
        KEY_FILE_NAME = '.ssh_key'

        private_class_method :new

        def self.open(params)
          ftp_connection = new(params)
          yield ftp_connection
        ensure
          ftp_connection.close if ftp_connection
        end

        def initialize(p)
          @host = p['sftp_host']
          @directory_path = p['sftp_directory_path']
          @filename_pattern = p['sftp_filename_pattern'] || '*'
          username = p['sftp_username']
          @maximum_number_to_transfer = p['sftp_maximum_number_to_transfer']
          options = connection_options_from_params p

          @sftp = Net::SFTP.start(@host, username, options)
        rescue => e
          raise convert_errors(e, host: @host)
        end

        def close
          @sftp.session.close if @sftp && !@sftp.session.closed?
        end

        def get_files
          failed_files = 0

          entries_to_transfer = @sftp.dir.glob(@directory_path, @filename_pattern)
          entries_to_transfer = entries_to_transfer.select{|e| e.file?}.first(@maximum_number_to_transfer)
          entries_to_transfer.each do |entry|
            file_attempts = 0

            relative_path = entry.name
            parent = File.dirname(relative_path)
            remote_path = File.join(@directory_path, relative_path)

            begin
              file_attempts += 1

              FileUtils.mkdir_p parent

              @sftp.download!(remote_path, relative_path)
              yield relative_path, nil if block_given?
              @sftp.remove!(remote_path)

              failed_files = 0
            rescue => e
              retry unless file_attempts >= 3
              converted_error = convert_errors(e, host: @host, file: relative_path)
              failed_files += 1
              yield relative_path, converted_error
              raise SFTPError, 'Three files failed in a row.  Aborting.' if failed_files == 3
            end
          end
        end

        def put_files
          local_files = Dir.glob(@filename_pattern)
          files_to_transfer = local_files.select{|f| File.file? f}.first(@maximum_number_to_transfer)
          failed_files = 0

          files_to_transfer.each do |local_path|
            parent = File.dirname(local_path)

            attempts_this_file = 0
            begin
              attempts_this_file += 1
              mkdir_p(parent)
              @sftp.upload!(local_path, File.join(@directory_path, local_path))
              yield local_path, nil if block_given?
              File.delete local_path if File.exists? local_path
              failed_files = 0
            rescue => e
              retry unless attempts_this_file >= 3
              converted_error = convert_errors(e, host: @host, file: local_path)
              failed_files += 1
              yield local_path, converted_error
              raise SFTPError, 'Three files failed in a row.  Aborting.' if failed_files == 3
            end
          end
        end

        def test_connection
          test_filename = 'sftp_test'
          test_file = Tempfile.new test_filename
          test_file.write 'This is test content'
          test_file.close
          remote_file = File.join(@directory_path, File.basename(test_file.path))

          @sftp.upload!(test_file.path, remote_file)
          sleep 1
          @sftp.remove!(remote_file)
          nil
        rescue => e
          e = convert_errors(e)
          return "SFTP Connection Test error: #{e.message}"
        ensure
          test_file.unlink if test_file
        end

        def mkdir_p(dir)
          full_dir = File.join(@directory_path, dir)
          Pathname.new(full_dir).descend do |path|
            path = path.to_s
            begin
              raise FileError, "Could not create #{dir}.  #{path} is a file." unless @sftp.stat!(path).directory?
            rescue Net::SFTP::StatusException => e
              if e.code == 2
                # File does not exist
                @sftp.mkdir!(path)
              else
                raise convert_errors(e, host: @host, file: dir)
              end
            rescue => e
              raise convert_errors(e, host: @host, file: dir)
            end
          end
        end

        def rmdir(dir)
          full_dir = File.join(@directory_path, dir)
          @sftp.rmdir! full_dir
        rescue => e
          raise convert_errors(e, host: @host, file: dir)
        end

        private def convert_sftp_status_exception(e, host: nil, file: nil)
          # Codes built from https://winscp.net/eng/docs/sftp_codes
          return e unless e.is_a? Net::SFTP::StatusException
          prefix = ''
          prefix << "Error on host #{host}: " if host
          prefix << "Error transferring file #{file}. " if file

          case e.code
            when 1
              FileError.new("#{prefix}An attempt to read past the end-of-file was made. (#{e.description})")
            when 2
              FileError.new("#{prefix}A reference was made to a file which does not exist. (#{e.description})")
            when 3
              PermissionError.new("#{prefix}The user does not have sufficient permissions to perform the operation. (#{e.description})")
            when 4
              SFTPError.new("#{prefix}An unknown error occurred. (#{e.description}): #{e.text}")
            when 5
              SFTPError.new("#{prefix}A badly formatted packet or other SFTP protocol incompatibility was detected. (#{e.description}")
            when 6
              ConnectionError.new("#{prefix}There is no connection to the server. (#{e.description})")
            when 7
              ConnectionError.new("#{prefix}The connection to the server was lost. (#{e.description})")
            when 8
              SFTPError.new("#{prefix}An attempted operation could not be completed by the server because the server does not support the operation. (#{e.description})")
            when 9
              FileError.new("#{prefix}The handle value was invalid. (#{e.description})")
            when 10
              FileError.new("#{prefix}The file path does not exist or is invalid. (#{e.description})")
            when 11
              FileError.new("#{prefix}The file already exists. (#{e.description})")
            when 12
              FileError.new("#{prefix}The file is on read-only media, or the media is write protected. (#{e.description})")
            when 13
              FileError.new("#{prefix}The requested operation cannot be completed because there is no media available in the drive. (#{e.description})")
            when 14
              FileError.new("#{prefix}The requested operation cannot be completed because there is insufficient free space on the filesystem. (#{e.description})")
            when 15
              FileError.new("#{prefix}The operation cannot be completed because it would exceed the user’s storage quota. (#{e.description})")
            when 16
              PermissionError.new("#{prefix}A principal referenced by the request. (either the owner, group, or who field of an ACL), was unknown. (#{e.description})")
            when 17
              FileError.new("#{prefix}The file could not be opened because it is locked by another process. (#{e.description})")
            when 18
              FileError.new("#{prefix}The directory is not empty. (#{e.description})")
            when 19
              FileError.new("#{prefix}The specified file is not a directory. (#{e.description})")
            when 20
              FileError.new("#{prefix}The filename is not valid. (#{e.description})")
            when 21
              FileError.new("#{prefix}Too many symbolic links encountered or, an SSH_FXF_NOFOLLOW open encountered a symbolic link as the final component. (#{e.description})")
            when 22
              FileError.new("#{prefix}The file cannot be deleted. (#{e.description})")
            when 23
              SFTPError.new("#{prefix}One of the parameters was out of range, or the parameters specified cannot be used together. (#{e.description})")
            when 24
              FileError.new("#{prefix}The specified file was a directory in a context where a directory cannot be used. (#{e.description})")
            when 25
              FileError.new("#{prefix}An read or write operation failed because another process’s mandatory byte-range lock overlaps with the request. (#{e.description})")
            when 26
              FileError.new("#{prefix}A request for a byte range lock was refused. (#{e.description})")
            when 27
              FileError.new("#{prefix}An operation was attempted on a file for which a delete operation is pending. (#{e.description})")
            when 28
              FileError.new("#{prefix}The file is corrupt. (#{e.description})")
            when 29
              PermissionError.new("#{prefix}The principal specified can not be assigned as an owner of a file. (#{e.description})")
            when 30
              PermissionError.new("#{prefix}The principal specified can not be assigned as the primary group of a file (#{e.description})")
            when 31
              FileError.new("#{prefix}The requested operation could not be completed because the specified byte range lock has not been granted. (#{e.description})")
            else
              SFTPError.new("#{prefix}Unexpected error occurred (#{e.description}): #{e.text}")
          end
        end

        private def convert_ssh_exception(e, host: nil, file: nil)
          return e unless e.is_a? Net::SSH::Exception
          prefix = ''
          prefix << "Error on host #{host}: " if host
          prefix << "Error transferring file #{file}. " if file

          case e
            when Net::SSH::AuthenticationFailed
              ConnectionError.new("#{prefix}Authentication failed: #{e.message}")
            when Net::SSH::ConnectionTimeout, Net::SSH::Timeout
              TimeoutError.new("#{prefix}Remote server timed out: #{e.message}")
            when Net::SSH::Disconnect
              ConnectionError.new("#{prefix}Remote server terminated connected unexpectedly: #{e.message}")
            when Net::SSH::HostKeyError
              ConnectionError.new("#{prefix}SSH Host Key Error: #{e.message}")
            else
              SFTPError.new("#{prefix}Unexpected error occurred: #{e.message}")
          end
        end

        private def convert_errors(e, host: nil, file: nil)
          case e
            when SFTPError
              e
            when Net::SSH::Exception
              convert_ssh_exception(e, host: host, file: file)
            when Net::SFTP::StatusException
              convert_sftp_status_exception(e, host: host, file: file)
            when SocketError
              ConnectionError.new("Unable to resolve host #{host}.")
            when Errno::ECONNREFUSED
              ConnectionError.new("The server #{host} refused the connection")
            else
              SFTPError.new("Unexpected SFTP error from host #{host}: #{e.message}")
          end
        end

        private def connection_options_from_params(p)
          connection_options = {}

          connection_options[:port] = p['sftp_port'] if p['sftp_port']
          connection_options[:password] = p['sftp_password'].plain_text if p['sftp_password']

          if p['sftp_key']
            File.write(KEY_FILE_NAME, p['sftp_key'])
            connection_options[:keys] = [KEY_FILE_NAME]
          end

          connection_options[:non_interactive] = true
          connection_options
        end
      end
    end
  end
end