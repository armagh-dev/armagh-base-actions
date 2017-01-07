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

require 'oci8'
require 'configh'

module Armagh
  module Support
    module Oracle
      include Configh::Configurable

      define_parameter name: 'db_connection_string',
        description: 'Oracle database connection string',
        prompt: 'username/password@127.0.0.1/DATABASE',
        type: 'string',
        required: true

      define_parameter name: 'type_bindings',
        description: 'Optional Oracle binding types hash',
        prompt: '{7 => Time}',
        type: 'hash',
        required: false

      class OracleError       < StandardError; end
      class InvalidQueryError < OracleError; end

      def query_oracle(query, config)
        raise InvalidQueryError, "Query must be a String, instead: #{query.class}" unless query.is_a?(String)
        raise InvalidQueryError, 'Query cannot be empty' if query.strip.empty?

        @db_connection = OracleClient.new(config.oracle.db_connection_string)
        @db_connection.query_and_fetch_rows(query, type_bindings: config.oracle.type_bindings) { |row| yield row }
      rescue OracleError
        raise
      rescue => e
        raise OracleError, e
      ensure
        @db_connection.logoff if @db_connection
      end

      class OracleClient < OCI8

        def query_and_fetch_rows(query, **opts)
          cursor = parse(query)

          if opts[:type_bindings]
            opts[:type_bindings].each do |col_number, klass|
              cursor.define(col_number, klass)
            end
          end

          cursor.exec
          cursor.fetch_hash { |row| yield row }
        rescue => e
          raise OracleError, e.message
        ensure
          cursor.close if cursor
        end

      end
      private_constant :OracleClient

    end
  end
end
