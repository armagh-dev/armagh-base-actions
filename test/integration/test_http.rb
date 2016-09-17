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


require_relative '../helpers/coverage_helper'

require 'test/unit'

require_relative '../../lib/armagh/support/http'

class TestIntegrationHTTP < Test::Unit::TestCase

  def setup
    config_values_from_file = load_local_integration_test_config
    @base_url    = config_values_from_file[ 'test_http_url']
    @content     = {}
  end
  
  def configure_connection( method, site, headers: {}, fields: {}, auth: {}, follow_redirects: true)

    site = File.join( @base_url, site ) unless site[ /^https?:/]
    config_values = { 'http' => { 'follow_redirects' => follow_redirects } }
    config_values[ 'http' ].merge!( {
      'method'  => method,
      'url'     => site,
      'headers' => headers,
      'fields'  => fields
    })
    unless auth.empty?
      config_values[ 'http' ].merge!( {
        'username' => auth[ 'username' ],
        'password' => auth[ 'password' ]
      })
    end
    @config_store = []
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'abc', config_values )
    @http = Armagh::Support::HTTP::Connection.new( config )
  end
  
  def fetch_site( override_url = nil, override_method = nil, override_fields = nil)
    response = @http.fetch( override_url, override_method, override_fields )
    @head = response['head']
    @content = response['body']
  end

  def fetch_page( override_url = nil, override_method = nil, override_fields = nil )
    override_url = File.join(@base_url, override_url ) if override_url
    fetch_site( override_url, override_method, override_fields )
  end

  def assert_content(expected)
    assert_include @content, expected
  end

  def load_local_integration_test_config
    config = nil
    config_filepath = File.join(__dir__, 'local_integration_test_config.json')

    begin
      config = JSON.load(File.read(config_filepath))
      errors = []
      if config.is_a? Hash
        %w(test_http_url).each do |k|
          errors << "Config file missing member #{k}" unless config.has_key?(k)
        end
      else
        errors << 'Config file should contain a hash of test_http_url'
      end

      raise errors.join("\n") unless errors.empty?
    rescue => e
      puts "Integration test environment not set up.  See test/integration/ftp_test.readme.  Detail: #{ e.message }"
      pend
    end
    config
  end

  def test_get_content
    configure_connection( Armagh::Support::HTTP::GET, 'page')
    fetch_page
    assert_content 'You have successfully located the page.  Have a nice day.'
  end

  def test_use_cookies
    configure_connection( Armagh::Support::HTTP::GET, 'check_cookie' )
    
    fetch_page
    assert_content "Bummer dude.  No cookies for you.  What'd you do wrong?"

    fetch_page('set_cookie')
    assert_content 'Woohoo! Cookies!'

    fetch_page
    assert_content 'AWESOME!  Cookies for everyone.'
  end

  def test_custom_headers
    configure_connection(Armagh::Support::HTTP::GET, 'headers', headers: {'Field-one' => 1, 'Another' => 'Testing'})
    fetch_page
    
    assert_content 'Headers!'
    assert_content '"HTTP_FIELD_ONE":"1"'
    assert_content '"HTTP_ANOTHER":"Testing"'
  end

  def test_modify_user_agent
    configure_connection(Armagh::Support::HTTP::GET, 'whats_my_agent')
    fetch_page
    assert_content "Your agent is #{Armagh::Support::HTTP::Connection::DEFAULT_HEADERS['User-Agent']}"

    configure_connection(Armagh::Support::HTTP::GET, 'whats_my_agent', headers: {'User-Agent' => 'TestAgent'})
    fetch_page
    assert_content 'Your agent is TestAgent'
  end

  def test_cookie_login_with_post
    configure_connection(Armagh::Support::HTTP::GET, 'cant_get_here_without_cookie_based_login')
    fetch_page
    assert_content 'Please log in to continue.'

    fetch_page('cookie_based_login', Armagh::Support::HTTP::POST )
    assert_content 'Fail, Loser'

    fields = {'secret' => 'wooptidoo', 'password' => 'friend', 'username' => 'test_user'}
    fetch_page( 'cookie_based_login', Armagh::Support::HTTP::POST, fields)
    assert_content 'Welcome, test_user!'

    fetch_page
    assert_content 'You made it!'
  end

  def test_http
    configure_connection(Armagh::Support::HTTP::GET, 'http://www.example.com/')
    fetch_site
    assert_content 'Example Domain'
  end

  def test_https
    configure_connection(Armagh::Support::HTTP::GET, 'https://www.example.com/')
    fetch_site
    assert_content 'Example Domain'
  end

  def test_basic_authentication
    configure_connection( Armagh::Support::HTTP::GET, 'http_basic_auth')
    expected = Armagh::Support::HTTP::ConnectionError.new("Unexpected HTTP response from 'https://testserver.noragh.com/suites/http_basic_auth': 401 - Unauthorized.")
    assert_raise(expected){fetch_page}

    auth = {'username' => 'testuser', 'password' => Configh::DataTypes::EncodedString.from_plain_text('testpass')}
    configure_connection(Armagh::Support::HTTP::GET, 'http_basic_auth', auth: auth)
    fetch_page
    assert_content 'Your credentials made me happy.'
  end

  def test_404
    configure_connection( Armagh::Support::HTTP::GET, 'not_a_valid_page')
    expected = Armagh::Support::HTTP::ConnectionError.new("Unexpected HTTP response from 'https://testserver.noragh.com/suites/not_a_valid_page': 404 - Not Found.")
    assert_raise(expected){fetch_page}
  end

  def test_redirection
    configure_connection(Armagh::Support::HTTP::GET, 'redirection')
    fetch_page
    assert_content 'You made it to the redirection target.'
  end

  def test_disabled_redirection
    configure_connection( Armagh::Support::HTTP::GET, 'redirection', follow_redirects: false )
    expected = Armagh::Support::HTTP::RedirectError.new("Attempted to redirect from 'https://testserver.noragh.com/suites/redirection' but redirection is not allowed.")
    assert_raise(expected){fetch_page}
  end

  def test_infinite_redirection
    configure_connection( Armagh::Support::HTTP::GET, 'infinite_redirection')
    expected = Armagh::Support::HTTP::RedirectError.new("Too many redirects from 'https://testserver.noragh.com/suites/infinite_redirection'.")
    assert_raise(expected){fetch_page}
  end

  def test_whitelist

  end

  def test_blacklist

  end
end
