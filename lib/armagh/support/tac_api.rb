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

require 'tac/web_services/web_services_v77'

module Armagh
  module Support
    class Tac
      attr_reader :tac_instance

      # class TacballDataTypeError < StandardError; end

      ALLOWED_ENDPOINTS = [
        :connections,
        :documents,
        :entities,
        :headlines,
        :feedcounts,
        :filter_counts,
        :histograms,
        :observers,
        :folder_headlines,
        :geo,
        :get_doc
      ]

      def self.connect( tac_hostname, user_id, password, cert_file=nil, key_file=nil )
        TAC::WebServices::TACInstance.connect(tac_hostname, user_id, password, cert_file, key_file)
      end

      def initialize( tac_hostname, user_id, password, cert_file=nil, key_file=nil )
        @tac_instance ||= TAC::WebServices::TACInstance.new(tac_hostname, user_id, password, cert_file, key_file)
      end

      def get( relative_url, args=nil )
        tac_instance.get(relative_url, args)
      end

      def get_version
        tac_instance.get_version
      end

      def verify( args = nil )
        tac_instance.verify(args)
      end

      def method_missing(method, *args)
        if ALLOWED_ENDPOINTS.include?(method)
          tac_instance.send(method, *args)
        else
          super
        end
      end

    end
  end
end
