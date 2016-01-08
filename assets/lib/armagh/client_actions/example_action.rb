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

require 'armagh/action'

module Armagh
  module ClientActions

    # TODO Replace this action with your own
    class ExampleAction < Armagh::Action

      # TODO Define the parameters you need the administrator to provide to use this action
      # Format: define_parameter(name, description, type, required = false, validation_callback = nil)
      #
      # Example for connecting to FTP:
      # define_parameter( 'host',     'FTP provider hostname', String,  'required' => true   )
      # define_parameter( 'user',     'User name',             String,  'required' => true)
      # define_parameter( 'password', 'Password',              String,  'required' => true )
      # define_parameter( 'port',     'Port',                  Integer, 'default' => 21, 'validation_callback' => 'port_is_valid?' )
      # define_parameter( 'passive',  'Use passive mode',      Boolean, 'default' => false )

      # TODO If necessary, define a validation for the configuration as a whole. For the FTP example,
      # you might want to try to connect to the server using the parameters above.  You don't need
      # to validate each parameter individually here - the GUI already provides type-checking or
      # per-field customized validation through the 'validation_callback' parameter.
      #
      # This method should return an error string or nil
      #
      # See the Armagh Development Guide for more information.
      def validate
        # connection = my_bogus_ftp_connection
        # connection.error ? connection.error_message : nil
      end

      # TODO Implement the logic for the action
      # In this example, we create a new documents from each line of the input document.
      # If the line is empty, we specify an error.
      def execute(doc_content, doc_meta)

        File.foreach(filename).with_index do |line, line_num|
          @logger.debug "Processing line #{line_num}"

          if line.empty?
            error "Line #{line_num} of #{doc_meta['id']} is empty"
          else
            line_meta = {'line_num' => line_num}
            insert_document(line, line_meta)
          end
        end
      end
    end
  end
end
