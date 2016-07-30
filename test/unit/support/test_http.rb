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

require 'test/unit'
require 'webmock/test_unit'
require 'mocha/test_unit'

require_relative '../../../lib/armagh/actions'
require_relative '../../helpers/coverage_helper'
require_relative '../../../lib/armagh/support/http'

class HTTPTestAction < Armagh::Actions::Action
  include Armagh::Support::HTTP
  attr_accessor :parameters
end

class TestHTTP < Test::Unit::TestCase

  def setup
    @expected_response = 'response body'
    @http = Armagh::Support::HTTP::Connection.new
  end

  def test_fetch_http_get
    stub_request(:get, 'http://fake.url').to_return(body: @expected_response)
    response = @http.fetch('http://fake.url')
    assert_equal(@expected_response, response['body'])
    assert_equal('200', response['head']['Status'])
    assert_equal(@expected_response.length.to_s, response['head']['Content-Length'])
  end

  def test_fetch_https_get
    stub_request(:get, 'https://fake.url').to_return(body: @expected_response)
    response = @http.fetch('https://fake.url')
    assert_equal(@expected_response, response['body'])
    assert_equal('200', response['head']['Status'])
    assert_equal(@expected_response.length.to_s, response['head']['Content-Length'])
  end

  def test_fetch_http_post
    stub_request(:post, 'http://fake.url').to_return(body: @expected_response)
    response = @http.fetch('http://fake.url', method: Armagh::Support::HTTP::POST)
    assert_equal(@expected_response, response['body'])
    assert_equal('200', response['head']['Status'])
    assert_equal(@expected_response.length.to_s, response['head']['Content-Length'])
  end

  def test_fetch_https_post
    stub_request(:post, 'https://fake.url').to_return(body: @expected_response)
    response = @http.fetch('https://fake.url', method: Armagh::Support::HTTP::POST)
    assert_equal(@expected_response, response['body'])
    assert_equal('200', response['head']['Status'])
    assert_equal(@expected_response.length.to_s, response['head']['Content-Length'])
  end

  def test_fetch_default_headers
    stub_request(:any, 'http://fake.url').with(headers: Armagh::Support::HTTP::Connection::DEFAULT_HEADERS)
    @http.fetch('http://fake.url')
  end

  def test_fetch_proxy
    proxy_config = {
        'url' => 'http://proxy.address',
        'user' => 'proxy user',
        'pass' => 'proxy pass'
    }

    proxy_set = sequence 'proxy_set'
    HTTPClient.any_instance.expects(:proxy=).with(nil).at_least(0).in_sequence(proxy_set)
    HTTPClient.any_instance.expects(:proxy=).with(proxy_config['url']).in_sequence(proxy_set)
    HTTPClient.any_instance.expects(:set_proxy_auth).with(proxy_config['user'], proxy_config['pass']).in_sequence(proxy_set)

    stub_request(:any, 'https://fake.url')
    @http.fetch('https://fake.url', proxy: proxy_config)
  end

  def test_fetch_auth
    auth_config = {
        'user' => 'username',
        'pass' => 'password',
        'cert' => 'cert string',
        'key' => 'key string',
        'key_pass' => 'key string'
    }
    stub_request(:any, 'https://fake.url').with(basic_auth: [auth_config['user'], auth_config['pass']])

    OpenSSL::X509::Certificate.expects(:new).with(auth_config['cert']).returns(:CERTIFICATE)
    OpenSSL::PKey::RSA.expects(:new).with(auth_config['key'], auth_config['key_pass']).returns(:KEY)

    @http.fetch('https://fake.url', auth: auth_config)
  end

  def test_fetch_headers
    headers = {
        'H1' => 'one',
        'H2' => 'two',
        'H3' => 'three',
        'Key' => 'four',
        'User-Agent' => 'test_agent'
    }

    stub_request(:any, 'http://fake.url').with(headers: headers)
    @http.fetch('http://fake.url', headers: headers)
  end

  def test_fetch_redirect
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: 'http://fake.url2'})
    stub_request(:any, 'http://fake.url2')
    @http.fetch('http://fake.url')
  end

  def test_fetch_too_many_redirect
    10.times do |i|
      stub_request(:any, "http://fake.url#{i}").to_return(:status => 302, :body => '', :headers => {Location: "http://fake.url#{i+1}"})
    end

    e = assert_raise(Armagh::Support::HTTP::RedirectError) {@http.fetch('http://fake.url0')}
    assert_equal("Too many redirects from 'http://fake.url0'.", e.message)
  end

  def test_fetch_disabled_redirects
    @http = Armagh::Support::HTTP::Connection.new(follow_redirects: false)
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: 'http://fake.url2'})
    e = assert_raise(Armagh::Support::HTTP::RedirectError) {@http.fetch('http://fake.url')}
    assert_equal("Attempted to redirect from 'http://fake.url' but redirection is not allowed.", e.message)
  end

  def test_fetch_too_many_redirect_response
    stub_request(:any, 'http://fake.url').to_raise(HTTPClient::BadResponseError.new('retry count exceeded'))
    e = assert_raise(Armagh::Support::HTTP::RedirectError) {@http.fetch('http://fake.url')}
    assert_equal("Too many redirects from 'http://fake.url'.", e.message)
  end

  def test_https_to_http_redirect_chain
    @http = Armagh::Support::HTTP::Connection.new(allow_https_to_http: false)
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: 'https://fake.url2'})
    stub_request(:any, 'https://fake.url2').to_return(:status => 302, :body => '', :headers => {Location: 'http://fake.url2'})
    stub_request(:any, 'http://fake.url2')
    assert_raise(Armagh::Support::HTTP::RedirectError.new("Attempted to redirect from an https resource to a no non-https resource while retrieving 'http://fake.url'.  Considering enabling allow_https_to_http.")){@http.fetch('http://fake.url')}
  end

  def test_https_to_http_redirect_chain_allowed
    @http = Armagh::Support::HTTP::Connection.new(allow_https_to_http: true)
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: 'https://fake.url2'})
    stub_request(:any, 'https://fake.url2').to_return(:status => 302, :body => '', :headers => {Location: 'http://fake.url2'})
    stub_request(:any, 'http://fake.url2')
    @http.fetch('http://fake.url')
  end

  def test_https_to_http_redirect_chain_allowed_relative
    @http = Armagh::Support::HTTP::Connection.new(allow_https_to_http: true)
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: '/something'})
    stub_request(:any, 'http://fake.url/something')
    @http.fetch('http://fake.url')
  end

  def test_unknown_bad_response
    stub_request(:any, 'http://fake.url').to_raise(HTTPClient::BadResponseError.new('bad response'))
    e = assert_raise(Armagh::Support::HTTP::ConnectionError) {@http.fetch('http://fake.url')}
    assert_equal("Unexpected error requesting 'http://fake.url' - bad response.", e.message)
  end

  def test_fetch_bad_protocol
    e = assert_raise(Armagh::Support::HTTP::URLError) {@http.fetch('nope://url')}
    assert_equal("'nope://url' is not a valid HTTP or HTTPS URL.", e.message)
  end

  def test_fetch_bad_url
    e = assert_raise(Armagh::Support::HTTP::URLError) {@http.fetch('bad url')}
    assert_equal("'bad url' is not a valid HTTP or HTTPS URL.", e.message)
  end

  def test_fetch_bad_method
    e = assert_raise(Armagh::Support::HTTP::MethodError) {@http.fetch('http://fake.url', method: 'bad')}
    assert_equal("Unknown HTTP method 'bad'.  Expected 'get' or 'post'.", e.message)
  end

  def test_fetch_no_proxy_user_or_pass
    expected_message = 'Unable to set proxy.  In order to use proxy authentication, both user and pass must be defined.'

    proxy_config = {
        'url' => 'http://proxy.address',
        'user' => 'proxy user',
        'pass' => 'proxy pass'
    }

    proxy = proxy_config.select{|k,v| k != 'user'}
    e = assert_raise(Armagh::Support::HTTP::ConfigurationError) {@http.fetch('http://fake.url', proxy: proxy)}
    assert_equal(expected_message, e.message)

    proxy = proxy_config.select{|k,v| k != 'pass'}
    e = assert_raise(Armagh::Support::HTTP::ConfigurationError) {@http.fetch('http://fake.url', proxy: proxy)}
    assert_equal(expected_message, e.message)
  end

  def test_bad_proxy
    proxy_config = {
        'url' => 'bad proxy',
        'user' => 'proxy user',
        'pass' => 'proxy pass'
    }
    e = assert_raise(Armagh::Support::HTTP::ConfigurationError) {@http.fetch('http://fake.url', proxy: proxy_config)}
    assert_equal('Unable to set proxy.  unsupported proxy bad proxy.', e.message)
  end

  def test_fetch_bad_cert
    auth_config = {
        'user' => 'username',
        'pass' => 'password',
        'cert' => 'cert string',
        'key' => 'key string',
    }
    stub_request(:any, 'https://fake.url').with(basic_auth: [auth_config['user'], auth_config['pass']])

    OpenSSL::X509::Certificate.expects(:new).with(auth_config['cert']).raises(RuntimeError, 'BAD CERTIFICATE')

    e = assert_raise(Armagh::Support::HTTP::ConfigurationError){@http.fetch('https://fake.url', auth: auth_config)}
    assert_equal('Unable to set authentication.  Certificate Error: BAD CERTIFICATE.', e.message)
  end

  def test_fetch_bad_key
    auth_config = {
        'user' => 'username',
        'pass' => 'password',
        'cert' => 'cert string',
        'key' => 'key string',
    }
    stub_request(:any, 'https://fake.url').with(basic_auth: [auth_config['user'], auth_config['pass']])

    OpenSSL::X509::Certificate.expects(:new).with(auth_config['cert']).returns(:CERTIFICATE)
    OpenSSL::PKey::RSA.expects(:new).with(auth_config['key'], auth_config['key_pass']).raises(RuntimeError, 'BAD KEY')

    e = assert_raise(Armagh::Support::HTTP::ConfigurationError){@http.fetch('https://fake.url', auth: auth_config)}
    assert_equal('Unable to set authentication.  Key Error: BAD KEY.', e.message)
  end

  def test_fetch_no_cert_or_key
    expected_message = 'Unable to set authentication.  In order to use SSL certificate authentication, both cert and key must be defined.'

    auth_config = {
        'cert' => 'cert string',
        'key' => 'key string',
    }

    auth = auth_config.select{|k,v| k != 'cert'}
    e = assert_raise(Armagh::Support::HTTP::ConfigurationError) {@http.fetch('http://fake.url', auth: auth)}
    assert_equal(expected_message, e.message)

    auth = auth_config.select{|k,v| k != 'key'}
    e = assert_raise(Armagh::Support::HTTP::ConfigurationError) {@http.fetch('http://fake.url', auth: auth)}
    assert_equal(expected_message, e.message)
  end

  def test_fetch_no_user_or_pass
    expected_message = 'Unable to set authentication.  In order to use authentication, both user and pass must be defined.'

    auth_config = {
        'user' => 'username',
        'pass' => 'password',
    }

    auth = auth_config.select{|k,v| k != 'user'}
    e = assert_raise(Armagh::Support::HTTP::ConfigurationError) {@http.fetch('http://fake.url', auth: auth)}
    assert_equal(expected_message, e.message)

    auth = auth_config.select{|k,v| k != 'pass'}
    e = assert_raise(Armagh::Support::HTTP::ConfigurationError) {@http.fetch('http://fake.url', auth: auth)}
    assert_equal(expected_message, e.message)
  end

  def test_fetch_bad_response
    stub_request(:any, 'http://fake.url').to_return(:status => [999, 'Invoked Error'], :body => '')
    e = assert_raise(Armagh::Support::HTTP::ConnectionError) {@http.fetch('http://fake.url')}
    assert_equal("Unexpected HTTP response from 'http://fake.url': 999 - Invoked Error.", e.message)
  end

  def test_fetch_timeout
    stub_request(:any, 'http://fake.url').to_timeout
    e = assert_raise(Armagh::Support::HTTP::ConnectionError) {@http.fetch('http://fake.url')}
    assert_equal("HTTP response from 'http://fake.url' timed out.", e.message)
  end

  def test_fetch_configuration_error
    stub_request(:any, 'http://fake.url').to_raise(HTTPClient::ConfigurationError.new('Invoked Configuration Error'))
    e = assert_raise(Armagh::Support::HTTP::ConfigurationError) {@http.fetch('http://fake.url')}
    assert_equal("HTTP configuration error from 'http://fake.url': Invoked Configuration Error.", e.message)
  end

  def test_fetch_unexpected_error
    stub_request(:any, 'http://fake.url').to_raise('Unexpected Error')
    e = assert_raise(Armagh::Support::HTTP::ConnectionError) {@http.fetch('http://fake.url')}
    assert_equal("Unexpected error requesting 'http://fake.url' - Unexpected Error.", e.message)
  end

  def test_check_method
    a = HTTPTestAction.new('', mock('caller'), 'logger', {}, mock)
    assert_nil a.check_method('post')
    assert_nil a.check_method('POST')
    assert_nil a.check_method('get')
    assert_nil a.check_method('GET')
    assert_equal 'Allowed HTTP Methods are ["post", "get"].  Was set to \'bad\'.', a.check_method('bad')
  end

  def test_custom_validation
    a = HTTPTestAction.new('', mock('caller'), 'logger', {}, mock)

    a.parameters = {'http_proxy_username' => '123'}
    assert_equal 'In order to use proxy authentication, both user and pass must be defined.', a.custom_validation

    a.parameters = {'http_proxy_password' => '123'}
    assert_equal 'In order to use proxy authentication, both user and pass must be defined.', a.custom_validation

    a.parameters = {'http_proxy_username' => '123', 'http_proxy_password' => '123'}
    assert_nil a.custom_validation

    a.parameters = {'http_certificate' => '123'}
    assert_equal 'In order to use SSL certificate authentication, both cert and key must be defined.', a.custom_validation

    a.parameters = {'http_key' => '123'}
    assert_equal 'In order to use SSL certificate authentication, both cert and key must be defined.', a.custom_validation

    a.parameters = {'http_certificate' => '123', 'http_key' => '123'}
    assert_nil a.custom_validation

    a.parameters = {'http_username' => '123'}
    assert_equal 'In order to use authentication, both user and pass must be defined.', a.custom_validation

    a.parameters = {'http_password' => '123'}
    assert_equal 'In order to use authentication, both user and pass must be defined.', a.custom_validation

    a.parameters = {'http_username' => '123', 'http_password' => '123'}
    assert_nil a.custom_validation
  end
end