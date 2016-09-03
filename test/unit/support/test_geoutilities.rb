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


require_relative '../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../lib/armagh/support/geoutilities'

class TestGeoUtilities < Test::Unit::TestCase
  def test_parse
    expected = {'number' => '1600', 'prefix' => '', 'street' => 'Pennsylvania', 'type' => 'Ave', 'suffix' => 'NW', 'unit' => '', 'city' => 'Washington', 'state' => 'DC', 'zip' => '20006'}
    assert_equal expected, Armagh::Support::GeoUtilities.parse('1600 Pennsylvania ave nw, Washington, DC 20006')
  end

  def test_parse_partial
    expected = {'number' => '123', 'prefix' => '', 'street' => 'Hammer', 'type' => 'St', 'suffix' => '', 'unit' => '', 'city' => '', 'state' => '', 'zip' => nil}
    assert_equal expected,  Armagh::Support::GeoUtilities.parse('123 Hammer St.')
  end

  def test_parse_nil
    assert_equal nil, Armagh::Support::GeoUtilities.parse(nil)
  end

  def test_normalize_address
    assert_equal '1600 Pennsylvania Ave Box 123, Washington ( District Of Columbia ) DC 20006', Armagh::Support::GeoUtilities.normalize_address('1600 Pennsylvania Ave', 'Box 123', 'Washington', 'dc', '20006')
  end

  def test_normalize_address_empty
    assert_empty Armagh::Support::GeoUtilities.normalize_address(nil, nil, nil, nil, nil)
  end

  def test_normalize_address_error
    e = RuntimeError.new('test error')
    GeoUtilities::USAddress.expects(:lines_city_state_zip).raises(e)
    assert_raise(Armagh::Support::GeoUtilities::GeoUtilitiesError){Armagh::Support::GeoUtilities.normalize_address(nil, nil, nil, nil, nil)}
  end

  def test_miles_between_zipcodes
    assert_equal(0, Armagh::Support::GeoUtilities.miles_between_zipcodes('20006','20006'))
  end

  def test_miles_between_zipcodes_nil
    assert_nil Armagh::Support::GeoUtilities.miles_between_zipcodes(nil, nil)
  end

  def test_miles_between_error
    e = RuntimeError.new('test error')
    GeoUtilities::ZipcodeDB.expects(:miles_between_zipcodes).raises(e)
    assert_raise(Armagh::Support::GeoUtilities::GeoUtilitiesError){Armagh::Support::GeoUtilities.miles_between_zipcodes('20006','20006')}
  end

  def test_county_from_zipcode
    assert_equal 'El Paso', Armagh::Support::GeoUtilities.county_from_zipcode('80829')
  end

  def test_county_from_zipcode_nil
    assert_nil Armagh::Support::GeoUtilities.county_from_zipcode('99999')
  end

  def test_county_from_zip_error
    e = RuntimeError.new('test error')
    GeoUtilities::ZipcodeDB.expects(:county_for_zipcode).raises(e)
    assert_raise(Armagh::Support::GeoUtilities::GeoUtilitiesError){Armagh::Support::GeoUtilities.county_from_zipcode('20006')}
  end

  def test_location_from_zipcode
    assert_equal 'Seattle (King) WA 98111', Armagh::Support::GeoUtilities.location_from_zipcode('98111')
  end

  def test_location_from_zipcode_nil
    assert_nil Armagh::Support::GeoUtilities.location_from_zipcode(nil)
  end

  def test_location_from_zipcode_error
    e = RuntimeError.new('test error')
    GeoUtilities::ZipcodeDB.expects(:ccsz_for_zipcode).raises(e)
    assert_raise(Armagh::Support::GeoUtilities::GeoUtilitiesError){Armagh::Support::GeoUtilities.location_from_zipcode('20006')}
  end
end
