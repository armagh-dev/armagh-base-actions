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

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../helpers/coverage_helper'
require_relative '../../../lib/armagh/support/tac_api'

class TestTac < Test::Unit::TestCase

  def setup
    @hostname         = "somehost"
    @user_id          = "123"
    @password         = "pa55word"
    @tac_api_class    = TAC::WebServices::TACInstance
    @tac_api_instance = @tac_api_class.new(@hostname, @user_id, @password)
    @tac              = Armagh::Support::Tac.new(@hostname, @user_id, @password)
    @get_response     = stub('get_response', status_code: 200)
    HTTPClient.any_instance.stubs(:get).returns(@get_response)
  end

  test ".connect" do
    @tac_api_class.expects(:connect)

    Armagh::Support::Tac.connect(@hostname, @user_id, @password)
  end

  test "#initialize" do
    @tac_api_class.expects(:new)

    Armagh::Support::Tac.new(@hostname, @user_id, @password)
  end

  test "#get" do
    url = "http://www.example.com"
    args = nil
    @tac_api_class.any_instance.expects(:get)
    @tac.get(url, args)
  end

  test "#get_version" do
    @tac_api_class.any_instance.expects(:get_version)
    @tac.get_version
  end

  test "#verify" do
    @tac_api_class.any_instance.expects(:verify)
    @tac.verify
  end

  test "#connections" do
    @tac_api_class.any_instance.expects(:connections)
    @tac.connections
  end

  test "#documents" do
    @tac_api_class.any_instance.expects(:documents)
    @tac.documents
  end

  test "#entities" do
    @tac_api_class.any_instance.expects(:entities)
    @tac.entities
  end

  test "#headlines" do
    @tac_api_class.any_instance.expects(:headlines)
    @tac.headlines
  end

  test "#feed_counts" do
    @tac_api_class.any_instance.expects(:feedcounts)
    @tac.feedcounts
  end

  test "#filter_counts" do
    @tac_api_class.any_instance.expects(:filter_counts)
    @tac.filter_counts
  end

  test "#histograms" do
    @tac_api_class.any_instance.expects(:histograms)
    @tac.histograms({'system_id' => '12345'})
  end

  test "#observers" do
    @tac_api_class.any_instance.expects(:observers)
    @tac.observers
  end

  test "#folder_headlines" do
    @tac_api_class.any_instance.expects(:folder_headlines)
    @tac.folder_headlines({'system_id' => '12345'})
  end

  test "#geo" do
    @tac_api_class.any_instance.expects(:geo)
    @tac.geo
  end

  test "#get_doc" do
    @tac_api_class.any_instance.expects(:get_doc)
    @tac.get_doc
  end

  test "fails when method can't be found" do
    assert_raise NoMethodError do
      @tac.some_undefined_method
    end
  end
end
