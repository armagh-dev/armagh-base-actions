# Copyright 2018 Noragh Analytics, Inc.
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
require 'geoutilities'

module Armagh
  module Support
    module GeoUtilities

      class GeoUtilitiesError < StandardError; end
      class ZipCodeError < GeoUtilitiesError; end

      module_function

      # Breaks a string into parts.
      # @param address [String] the address to parse
      # @return [Hash] elements of the address (number, prefix, street, type, suffix, unit, city, state, zip).  nil if parsing resulted in no information.
      # @raise [GeoUtilitiesError] an unknown error occurred
      def parse(address)
        result = ::GeoUtilities::StreetAddress.parse(address.to_s)
        result ? result : nil
      rescue => e
        raise GeoUtilitiesError, "An unexpected error occurred while parsing '#{address}': #{e.message}"
      end

      # Normalizes an address
      # @param addr1 [String] address line 1
      # @param addr2 [String] address line 2
      # @param city [String] city
      # @param state [String] state
      # @param zip [String] zip code
      # @return [String] normalized address
      # @raise [ZipCodeError] the zip code is an invalid format
      # @raise [GeoUtilitiesError] an unknown error occurred
      def normalize_address(addr1, addr2 = '', city, state, zip)
        zip = zip.to_s
        raise ZipCodeError, "Zip code '#{zip}' is invalid" unless valid_zip?(zip)
        begin
          ::GeoUtilities::USAddress.lines_city_state_zip(addr1, addr2, city, state, zip).normalize.to_s.strip
        rescue => e
          raise GeoUtilitiesError, "An unexpected error occurred while normalizing '#{addr1}, #{addr2}, #{city}, #{state}, #{zip}': #{e.message}"
        end
      end

      # Miles between two zip codes
      # @param zip1 [String] zip code
      # @param zip2 [String] zip code
      # @return [Integer] number of miles between zip codes.  Nil if no distance could be calculated.
      # @raise [ZipCodeError] the zip code is an invalid format
      # @raise [GeoUtilitiesError] an unknown error occurred
      def miles_between_zipcodes(zip1, zip2)
        return nil unless zip1 && zip2
        zip1 = zip1.to_s
        zip2 = zip2.to_s
        raise ZipCodeError, "Zip code '#{zip1}' is invalid" unless valid_zip?(zip1)
        raise ZipCodeError, "Zip code '#{zip2}' is invalid" unless valid_zip?(zip2)
        begin
          ::GeoUtilities::ZipcodeDB.miles_between_zipcodes(zip1, zip2)
        rescue => e
          raise GeoUtilitiesError, "An unexpected error occurred while calculating miles between '#{zip1}' and '#{zip2}': #{e.message}"
        end
      end

      # County that a given zip code is in
      # @param zip [String] zip code
      # @return [String] county name.  Nil if no county could be found.
      # @raise [ZipCodeError] the zip code is an invalid format
      # @raise [GeoUtilitiesError] an unknown error occurred.
      def county_from_zipcode(zip)
        return nil unless zip
        zip = zip.to_s
        raise ZipCodeError, "Zip code '#{zip}' is invalid" unless valid_zip?(zip)
        begin
          ::GeoUtilities::ZipcodeDB.county_for_zipcode(zip)
        rescue => e
          raise GeoUtilitiesError, "An unexpected error occurred while retrieving county for zip '#{zip}': #{e.message}"
        end
      end

      # City, County, State, Zip that a given zip code is in
      # @param zip [String] zip code
      # @return [String] City (County) State Zip.  Nil if no information could be found.
      # @raise [ZipCodeError] the zip code is an invalid format
      # @raise [GeoUtilitiesError] an unknown error occurred.
      def location_from_zipcode(zip)
        return nil unless zip
        zip = zip.to_s
        raise ZipCodeError, "Zip code '#{zip}' is invalid" unless valid_zip?(zip)
        begin
          ::GeoUtilities::ZipcodeDB.ccsz_for_zipcode(zip)
        rescue => e
          raise GeoUtilitiesError, "An unexpected error occurred while retrieving city, county, state, zip for zip '#{zip}': #{e.message}"
        end
      end

      private_class_method def valid_zip?(zip)
        zip_length = zip.gsub(/\D/,'').length
        zip_length == 5 || zip_length == 9 || zip_length == 0
      end
    end
  end
end
