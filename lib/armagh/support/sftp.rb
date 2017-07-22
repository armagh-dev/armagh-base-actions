# Copyright 2017 Noragh Analytics, Inc.
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

require 'configh'

require_relative '../base/errors/armagh_error'

module Armagh
  module Support
    module SFTP
      include Configh::Configurable

       class SFTPError       < ArmaghError; notifies :ops; end
       class ConnectionError < SFTPError;   end
       class PermissionError < SFTPError;   end
       class FileError       < SFTPError;   end
       class TimeoutError    < SFTPError;   end

      define_parameter name: 'host', description: 'SFTP host or IP', type: 'populated_string', required: true, prompt: 'host.example.com or 10.0.0.1'
      define_parameter name: 'port', description: 'SFTP port', type: 'positive_integer', required: true, default: 22
      define_parameter name: 'directory_path', description: 'SFTP base directory path', type: 'populated_string', required: true, default: './'
      define_parameter name: 'duplicate_put_directory_paths', description: 'Directories receiving duplicate files on the same server', type: 'string_array', required: false, default: []
      define_parameter name: 'create_directory_path', description: 'If the target directory does not exist, create it', type: 'boolean', required: true, default: false
      define_parameter name: 'filename_pattern', description: 'Glob file pattern', type: 'string', required: false, prompt: '*.pdf'
      define_parameter name: 'username', description: 'SFTP user name', type: 'populated_string', required: true, prompt: 'user'
      define_parameter name: 'password', description: 'SFTP user password', type: 'encoded_string', required: false, prompt: 'password'
      define_parameter name: 'key', description: 'SSH Key (not filename!) for SFTP connection', type: 'string', required: false, prompt: 'password'
      define_parameter name: 'maximum_transfer', description: 'Max documents matching filter to collect or put in one run', type: 'positive_integer', default: 50, required: true

      define_group_test_callback callback_class: Armagh::Support::SFTP, callback_method: :test_connection
      define_group_validation_callback callback_class: Armagh::Support::SFTP, callback_method: :test_connection

      def SFTP.archive_config
        return @archive_config if @archive_config

        sftp_config = {
          'host' => ENV['ARMAGH_ARCHIVE_HOST'],
          'directory_path' => ENV['ARMAGH_ARCHIVE_PATH'],
          'username' => ENV['ARMAGH_ARCHIVE_USER'] || ENV['USER'],
          'create_directory_path' => true
        }
        sftp_config['port'] = ENV['ARMAGH_ARCHIVE_PORT'].to_i if ENV['ARMAGH_ARCHIVE_PORT']

        @archive_config = Armagh::Support::SFTP.create_configuration([], 'archive', {
          'sftp' => sftp_config})
      end

      def SFTP.test_connection(candidate_config)
        error = nil
        begin
          Connection.open(candidate_config) do |sftp|
            error = sftp.test_connection
          end
        rescue => e
          error = e.message
        end
        error
      end

      class Connection
        KEY_FILE_NAME = '.ssh_key'

        private_class_method :new

        def self.open(config)
          ftp_connection = new(config)
          yield ftp_connection
        ensure
          ftp_connection.close if ftp_connection
        end

        def initialize(config)
          sc = config.sftp

          @host = sc.host
          @directory_path = sc.directory_path
          @duplicate_put_directory_paths = sc.duplicate_put_directory_paths
          @create_directory_path = sc.create_directory_path
          @filename_pattern = sc.filename_pattern || '*'
          username = sc.username
          @maximum_number_to_transfer = sc.maximum_transfer
          options = connection_options_from_params config

          @sftp = Net::SFTP.start(@host, username, options)
        rescue => e
          raise convert_errors(e, host: @host)
        end

        def close
          @sftp.session.close if @sftp && !@sftp.session.closed?
        end

        #
        # files to transfer can be in subdirectories.
        # the subdirectory structure is preserved in transfer.
        # example:
        #    @directory_path is fred/
        #    remote files are fred/alice/file1, fred/alice/file2, fred/martha/file3, fred/file4
        #    then files will be created locally as, and yielded to block as:
        #       alice/file1, alice/file2, martha/file3, file4
        #
        def get_files
          failed_files = 0

          entries_to_transfer = @sftp.dir.glob(@directory_path, @filename_pattern)
          entries_to_transfer = entries_to_transfer.select { |e| e.file? }.first(@maximum_number_to_transfer)
          entries_to_transfer.each do |entry|
            file_attempts = 0

            remote_relative_filepath = entry.name
            remote_relative_dirpath  = File.dirname(remote_relative_filepath)
            remote_full_filepath     = File.join(@directory_path, remote_relative_filepath)

            attributes = entry.attributes.attributes.collect { |k, v| [k.to_s, v] }.to_h
            attributes['mtime'] = Time.at(attributes['mtime']).utc if attributes['mtime']
            attributes['atime'] = Time.at(attributes['atime']).utc if attributes['atime']
            begin
              file_attempts += 1

              local_dirpath  = remote_relative_dirpath
              local_filepath = remote_relative_filepath
              FileUtils.mkdir_p local_dirpath

              @sftp.download!(remote_full_filepath, local_filepath)
              yield local_filepath, attributes, nil if block_given?
              @sftp.remove!(remote_full_filepath)

              failed_files = 0
            rescue => e
              retry unless file_attempts >= 3
              converted_error = convert_errors(e, host: @host, file: remote_relative_filepath)
              failed_files += 1
              yield remote_relative_filepath, attributes, converted_error
              raise SFTPError, 'Three files failed in a row.  Aborting.' if failed_files == 3
            end
          end
        end

        # subdirectories are preserved across the put.
        #
        def put_files
          local_filepaths = Dir.glob(@filename_pattern)
          files_to_transfer = local_filepaths.select { |f| File.file? f }.first(@maximum_number_to_transfer)
          failed_files = 0

          remote_base_dirpaths = [ @directory_path, *@duplicate_put_directory_paths ]

          files_to_transfer.each do |local_filepath|

            raise SFTPError, "Local file #{ local_filepath } does not exist" unless File.exists?(local_filepath)

            attempts_this_file = 0
            begin
              attempts_this_file += 1
              remote_base_dirpaths.each do |remote_base_dirpath|
                remote_full_filepath = File.join( remote_base_dirpath, local_filepath )
                mkdir_p( File.dirname( remote_full_filepath ))
                @sftp.upload!( local_filepath, remote_full_filepath )
              end

              yield local_filepath, nil if block_given?
              File.delete local_filepath if File.exists? local_filepath
              failed_files = 0

            rescue => e
              retry if attempts_this_file < 3
              converted_error = convert_errors(e, host: @host, file: local_filepath)
              failed_files += 1
              yield local_filepath, converted_error
              raise SFTPError, 'Three files failed in a row.  Aborting.' if failed_files == 3
            end
          end
        end

        # if src has relative dir components, they are preserved across the put.  for example:
        # @directory_path = 'base'
        # dest_dir = 'fred'
        # src = 'alice/file1'
        # remote file path is base/fred/alice/file1
        #
        def put_file(src, dest_dir)
          raise FileError, "Local file '#{src}' is not a file." unless File.file? src

          attempts = 0
          begin
            attempts += 1

            [ @directory_path, *@duplicate_put_directory_paths ].each do |remote_base_dirpath|
              remote_full_dirpath = File.join( remote_base_dirpath, dest_dir, File.dirname( src ))
              mkdir_p( remote_full_dirpath ) if @create_directory_path
              @sftp.upload!(src, File.join(remote_full_dirpath, File.basename(src)))
            end
          rescue => e
            retry if attempts < 3
            raise convert_errors(e, host: @host, file: src)
          end
        end

        def remove(path)
          @sftp.session.exec!("rm -rf #{path}")
        rescue => e
          raise convert_errors(e, host: @host, file: path)
        end

        def remove_subpath( path )
          remove( File.join( @directory_path, path ))
        end

        def test_connection
          error = nil
          test_filename = 'sftp_test'
          test_file = Tempfile.new test_filename
          test_file.write 'This is test content'
          test_file.close
          remote_file = File.join(@directory_path, File.basename(test_file.path))
          mksubdir_p('') if @create_directory_path

          @sftp.upload!(test_file.path, remote_file)
          sleep 1
          @sftp.remove!(remote_file)
          nil
        rescue => e
          error = convert_errors(e)
          error = "SFTP Connection Test Error: #{error.message}"
        ensure
          test_file.unlink if test_file
          return error
        end

        def mkdir_p(full_dir)
          Pathname.new(full_dir).descend do |path|
            path = path.to_s
            begin
              raise FileError, "Could not create #{full_dir}.  #{path} is a file." unless @sftp.stat!(path).directory?
            rescue Net::SFTP::StatusException => e
              if e.code == 2
                # Dir does not exist
                @sftp.mkdir!(path)
              else
                raise convert_errors(e, host: @host, file: full_dir)
              end
            rescue => e
              raise convert_errors(e, host: @host, file: full_dir)
            end
          end
        end

        def mksubdir_p( path )
          mkdir_p( File.join( @directory_path, path ))
        end

        def rmdir(full_dir)
          @sftp.rmdir! full_dir
        rescue => e
          raise convert_errors(e, host: @host, file: full_dir)
        end

        def rmsubdir(dir)
          rmdir( File.join( @directory_path, dir ))
        end


        def ls(full_dir)
          @sftp.dir.entries(full_dir).lazy.collect { |i| i.name }.select { |i| i != '..' && i != '.' }.sort
        rescue => e
          raise convert_errors(e, host: @host, file: full_dir)
        end

        def ls_subdir(dir)
          ls( File.join( @directory_path, dir ))
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
              SFTPError.new("#{prefix}Unexpected error occurred (#{e.description}): #{e.text.class}")
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

        private def connection_options_from_params(config)
          sc = config.sftp
          connection_options = {}

          connection_options[:port] = sc.port if sc.port
          connection_options[:password] = sc.password.plain_text if sc.password

          if sc.key

            File.write(KEY_FILE_NAME, sc.key)
            connection_options[:keys] = [KEY_FILE_NAME]
          end

          connection_options[:non_interactive] = true
          connection_options
        end
      end
    end
  end
end
