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
    @config = load_local_integration_test_config
    @url = @config['test_http_url']

    @http = Armagh::Support::HTTP::Connection.new
    @content = {}
  end

  def fetch_site(method, site, headers: {}, fields: {}, auth: {})
    response = @http.fetch(site, method: method, headers: headers, fields: fields, auth: auth)
    @head = response['head']
    @content = response['body']
  end

  def fetch_page(method, page, headers: {}, fields: {}, auth: {})
    fetch_site(method, File.join(@url, page), headers: headers, fields: fields, auth: auth)
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
    fetch_page(Armagh::Support::HTTP::GET, 'page')
    assert_content 'You have successfully located the page.  Have a nice day.'
  end

  def test_use_cookies
    fetch_page(Armagh::Support::HTTP::GET, 'check_cookie')
    assert_content "Bummer dude.  No cookies for you.  What'd you do wrong?"

    fetch_page(Armagh::Support::HTTP::GET, 'set_cookie')
    assert_content 'Woohoo! Cookies!'

    fetch_page(Armagh::Support::HTTP::GET, 'check_cookie')
    assert_content 'AWESOME!  Cookies for everyone.'
  end

  def test_custom_headers
    fetch_page(Armagh::Support::HTTP::GET, 'headers', headers: {'Field-one' => 1, 'Another' => 'Testing'})

    assert_content 'Headers!'
    assert_content '"HTTP_FIELD_ONE":"1"'
    assert_content '"HTTP_ANOTHER":"Testing"'
  end

  def test_modify_user_agent
    fetch_page(Armagh::Support::HTTP::GET, 'whats_my_agent')
    assert_content "Your agent is #{Armagh::Support::HTTP::Connection::DEFAULT_HEADERS['User-Agent']}"

    fetch_page(Armagh::Support::HTTP::GET, 'whats_my_agent', headers: {'User-Agent' => 'TestAgent'})
    assert_content 'Your agent is TestAgent'
  end

  def test_cookie_login_with_post
    fetch_page(Armagh::Support::HTTP::GET, 'cant_get_here_without_cookie_based_login')
    assert_content 'Please log in to continue.'

    fetch_page(Armagh::Support::HTTP::POST, 'cookie_based_login')
    assert_content 'Fail, Loser'

    fields = {'secret' => 'wooptidoo', 'password' => 'friend', 'username' => 'test_user'}
    fetch_page(Armagh::Support::HTTP::POST, 'cookie_based_login', fields: fields)
    assert_content 'Welcome, test_user!'

    fetch_page(Armagh::Support::HTTP::GET, 'cant_get_here_without_cookie_based_login')
    assert_content 'You made it!'
  end

  def test_http
    fetch_site(Armagh::Support::HTTP::GET, 'http://www.example.com/')
    assert_content 'Example Domain'
  end

  def test_https
    fetch_site(Armagh::Support::HTTP::GET, 'https://www.example.com/')
    assert_content 'Example Domain'
  end

  def test_basic_authentication
    expected = Armagh::Support::HTTP::ConnectionError.new("Unexpected HTTP response from 'https://testserver.noragh.com/suites/http_basic_auth': 401 - Unauthorized.")
    assert_raise(expected){fetch_page(Armagh::Support::HTTP::GET, 'http_basic_auth')}

    auth = {'user' => 'testuser', 'pass' => 'testpass'}
    fetch_page(Armagh::Support::HTTP::GET, 'http_basic_auth', auth: auth)
    assert_content 'Your credentials made me happy.'
  end

  def test_404
    expected = Armagh::Support::HTTP::ConnectionError.new("Unexpected HTTP response from 'https://testserver.noragh.com/suites/not_a_valid_page': 404 - Not Found.")
    assert_raise(expected){fetch_page(Armagh::Support::HTTP::GET, 'not_a_valid_page')}
  end

  def test_redirection
    fetch_page(Armagh::Support::HTTP::GET, 'redirection')
    assert_content 'You made it to the redirection target.'
  end

  def test_disabled_redirection
    @http = Armagh::Support::HTTP::Connection.new(follow_redirects: false)
    expected = Armagh::Support::HTTP::RedirectError.new("Attempted to redirect from 'https://testserver.noragh.com/suites/redirection' but redirection is not allowed.")
    assert_raise(expected){fetch_page(Armagh::Support::HTTP::GET, 'redirection')}
  end

  def test_infinite_redirection
    expected = Armagh::Support::HTTP::RedirectError.new("Too many redirects from 'https://testserver.noragh.com/suites/infinite_redirection'.")
    assert_raise(expected){fetch_page(Armagh::Support::HTTP::GET, 'infinite_redirection')}
  end
end
