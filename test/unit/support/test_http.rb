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
    @config_store = []
    @original_verbose = $VERBOSE
  end

  def test_fetch_http_get
    stub_request(:get, 'http://fake.url').to_return(body: @expected_response)   
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httpget', { 'http' => { 'url' => 'http://fake.url' }})
    @http = Armagh::Support::HTTP::Connection.new( config )
    response = @http.fetch
    assert_equal(1, response.length)
    assert_equal(@expected_response, response.first['body'])
    assert_equal('200', response.first['head']['Status'])
    assert_equal(@expected_response.length.to_s, response.first['head']['Content-Length'])
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_https_get
    stub_request(:get, 'https://fake.url').to_return(body: @expected_response)
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httpsget', { 'http' => { 'url' => 'https://fake.url' }})
    @http = Armagh::Support::HTTP::Connection.new( config )
    response = @http.fetch
    assert_equal(1, response.length)
    assert_equal(@expected_response, response.first['body'])
    assert_equal('200', response.first['head']['Status'])
    assert_equal(@expected_response.length.to_s, response.first['head']['Content-Length'])
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_http_post
    stub_request(:post, 'http://fake.url').to_return(body: @expected_response)
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httppost', { 
      'http' => { 'url' => 'http://fake.url', 'method' => 'post'  }
    })
    @http = Armagh::Support::HTTP::Connection.new( config )
    response = @http.fetch
    assert_equal(1, response.length)
    assert_equal(@expected_response, response.first['body'])
    assert_equal('200', response.first['head']['Status'])
    assert_equal(@expected_response.length.to_s, response.first['head']['Content-Length'])
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_https_post
    stub_request(:post, 'https://fake.url').to_return(body: @expected_response)
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httpspost', { 
      'http' => { 'url' => 'https://fake.url', 'method' => 'post'  }
    })
    @http = Armagh::Support::HTTP::Connection.new( config )
    response = @http.fetch
    assert_equal(1, response.length)
    assert_equal(@expected_response, response.first['body'])
    assert_equal('200', response.first['head']['Status'])
    assert_equal(@expected_response.length.to_s, response.first['head']['Content-Length'])
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_default_headers
    stub_request(:any, 'http://fake.url').with(headers: Armagh::Support::HTTP::Connection::DEFAULT_HEADERS)
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'defhead', { 
      'http' => { 'url' => 'http://fake.url', 'method' => 'post'  }
    })
    @http = Armagh::Support::HTTP::Connection.new( config )
    @http.fetch
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_proxy
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'fetchproxy', { 
      'http' => { 'url' => 'https://fake.url', 
                  'proxy_url' => 'http://proxy.address',
                  'proxy_username' => 'proxy user',
                  'proxy_password' => Configh::DataTypes::EncodedString.from_plain_text('proxy pass')
      }
    })
    proxy_set = sequence 'proxy_set'
    HTTPClient.any_instance.expects(:proxy=).with(nil).at_least(0).in_sequence(proxy_set)
    HTTPClient.any_instance.expects(:proxy=).with('http://proxy.address').in_sequence(proxy_set)
    HTTPClient.any_instance.expects(:set_proxy_auth).with( 'proxy user', 'proxy pass').in_sequence(proxy_set)

    stub_request(:any, 'https://fake.url')
    @http = Armagh::Support::HTTP::Connection.new( config )
    @http.fetch
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_auth
    
    OpenSSL::X509::Certificate.expects(:new).twice.with( 'cert string' ).returns(:CERTIFICATE)
    OpenSSL::PKey::RSA.expects(:new).twice.with( 'key string', 'key string').returns(:KEY)
 
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'fetchauth', { 
      'http' => { 'url' => 'https://fake.url', 
        'username'     => 'username',
        'password'     => Configh::DataTypes::EncodedString.from_plain_text( 'password' ),
        'certificate'  => 'cert string',
        'key'          => 'key string',
        'key_password' => Configh::DataTypes::EncodedString.from_plain_text('key string' )
       }
    })
    @http = Armagh::Support::HTTP::Connection.new( config )
    stub_request(:any, 'https://fake.url').with(basic_auth: [ 'username', 'password' ])

    @http.fetch
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_headers
    headers = {
                  'H1' => 'one',
                  'H2' => 'two',
                  'H3' => 'three',
                  'Key' => 'four',
                  'User-Agent' => 'test_agent'
              }

    config = Armagh::Support::HTTP.create_configuration( @config_store, 'fetchhead', { 'http' => {  'url' => 'http://fake.url', 'headers' => headers }})
    stub_request(:any, 'http://fake.url').with(headers: headers)
    @http = Armagh::Support::HTTP::Connection.new( config )
    @http.fetch
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_redirect
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'fetchredir', { 'http' => { 'url' => 'http://fake.url'}})
    @http = Armagh::Support::HTTP::Connection.new( config )
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: 'http://fake.url2'})
    stub_request(:any, 'http://fake.url2')
    @http.fetch
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_too_many_redirect
    10.times do |i|
      stub_request(:any, "http://fake.url#{i}").to_return(:status => 302, :body => '', :headers => {Location: "http://fake.url#{i+1}"})
    end
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'tmdir', { 'http' => { 'url' => 'http://fake.url0'}})
    @http = Armagh::Support::HTTP::Connection.new( config )
    e = assert_raise(Armagh::Support::HTTP::RedirectError) {@http.fetch }
    assert_equal("Too many redirects from 'http://fake.url0'.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_disabled_redirects
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'disredir', { 'http' => { 'url' => 'http://fake.url', 'follow_redirects' => false }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: 'http://fake.url2'})
    e = assert_raise(Armagh::Support::HTTP::RedirectError) {@http.fetch}
    assert_equal("Attempted to redirect from 'http://fake.url' but redirection is not allowed.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_too_many_redirect_response
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'tmredres', { 'http' => { 'url' => 'http://fake.url' }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:any, 'http://fake.url').to_raise(HTTPClient::BadResponseError.new('retry count exceeded'))
    e = assert_raise(Armagh::Support::HTTP::RedirectError) {@http.fetch}
    assert_equal("Too many redirects from 'http://fake.url'.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_https_to_http_redirect_chain
    config = Armagh::Support::HTTP.create_configuration( @config_store, 's2rred', { 'http' => { 'url' => 'http://fake.url', 'allow_https_to_http' => false }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: 'https://fake.url2'})
    stub_request(:any, 'https://fake.url2').to_return(:status => 302, :body => '', :headers => {Location: 'http://fake.url2'})
    stub_request(:any, 'http://fake.url2')
    assert_raise(Armagh::Support::HTTP::RedirectError.new("Attempted to redirect from an https resource to a no non-https resource while retrieving 'http://fake.url'.  Considering enabling allow_https_to_http.")){@http.fetch}
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_https_to_http_redirect_chain_allowed
    config = Armagh::Support::HTTP.create_configuration( @config_store, 's2preall', { 'http' => { 'url' => 'http://fake.url', 'allow_https_to_http' => true }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: 'https://fake.url2'})
    stub_request(:any, 'https://fake.url2').to_return(:status => 302, :body => '', :headers => {Location: 'http://fake.url2'})
    stub_request(:any, 'http://fake.url2')
    @http.fetch
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_https_to_http_redirect_chain_allowed_relative
    config = Armagh::Support::HTTP.create_configuration( @config_store, 's2prcar', { 'http' => { 'url' => 'http://fake.url', 'allow_https_to_http' => true }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: '/something'})
    stub_request(:any, 'http://fake.url/something')
    @http.fetch
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_instant_client_side_redirects
    expected_response = "\t<html>\r\n\t<head>\r\n\t\t<meta http-equiv=\"refresh\" content=\"0; url=/salmonella/live-poultry-06-17/index.html\">\t</head>\r\n\t<body></body>\r\n\t</html>\r\n"
    stub_request(:get, 'http://fake.url').to_return(body: expected_response)
    stub_request(:get, 'http://fake.url/salmonella/live-poultry-06-17/index.html').to_return(body: @expected_response)
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httpget', { 'http' => { 'url' => 'http://fake.url' }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    response = @http.fetch
    assert_equal(1, response.length)
    assert_equal(@expected_response, response.first['body'])
    assert_equal('200', response.first['head']['Status'])
    assert_equal(@expected_response.length.to_s, response.first['head']['Content-Length'])
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_with_multiple_allowed_instant_client_side_redirects
    response1 = "\t<html>\r\n\t<head>\r\n\t\t<meta http-equiv=\"refresh\" content=\"0; url=/salmonella/live-poultry-06-17/index.html\">\t</head>\r\n\t<body></body>\r\n\t</html>\r\n"
    response2 = "\t<html>\r\n\t<head>\r\n\t\t<meta http-equiv=\"refresh\" content=\"0; url=/salmonella/more-live-poultry-06-17/index.html\">\t</head>\r\n\t<body></body>\r\n\t</html>\r\n"
    response3 = "\t<html>\r\n\t<head>\r\n\t\t<meta http-equiv=\"refresh\" content=\"0; url=/salmonella/even-more-live-poultry-06-17/index.html\">\t</head>\r\n\t<body></body>\r\n\t</html>\r\n"
    stub_request(:get, 'http://fake.url').to_return(body: response1)
    stub_request(:get, 'http://fake.url/salmonella/live-poultry-06-17/index.html').to_return(body: response2)
    stub_request(:get, 'http://fake.url/salmonella/more-live-poultry-06-17/index.html').to_return(body: response3)
    stub_request(:get, 'http://fake.url/salmonella/even-more-live-poultry-06-17/index.html').to_return(body: @expected_response)
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httpget', { 'http' => { 'url' => 'http://fake.url' }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    response = @http.fetch
    assert_equal(1, response.length)
    assert_equal(@expected_response, response.first['body'])
    assert_equal('200', response.first['head']['Status'])
    assert_equal(@expected_response.length.to_s, response.first['head']['Content-Length'])
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_with_multiple_maximum_instant_client_side_redirects
    response1 = "<html><head><meta http-equiv=\"refresh\" content=\"0; url=/response1.html\"></head><body></body></html>"
    stub_request(:get, 'http://fake.url').to_return(body: response1)
    10.times do |i|
      stub_request(:any, "http://fake.url/response#{i}.html").to_return(body: "<html><head><meta http-equiv=\"refresh\" content=\"0; url=/response#{i+1}.html\"></head><body></body></html>")
    end
    stub_request(:get, 'http://fake.url/response10.html').to_return(body: @expected_response)
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httpget', { 'http' => { 'url' => 'http://fake.url' }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    e = assert_raise(Armagh::Support::HTTP::RedirectError) {@http.fetch}
    assert_equal("Reached maximum allowed instant client-side redirects for http://fake.url/response10.html", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_unknown_bad_response
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'badres', { 'http' => { 'url' => 'http://fake.url' }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:any, 'http://fake.url').to_raise(HTTPClient::BadResponseError.new('bad response'))
    e = assert_raise(Armagh::Support::HTTP::ConnectionError) {@http.fetch}
    assert_equal("Unexpected error requesting 'http://fake.url' - bad response.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_config_bad_protocol
    e = assert_raise(Configh::ConfigInitError) { Armagh::Support::HTTP.create_configuration( @config_store, 'a', { 'http' => { 'url' => 'nope://url' }})}
    assert_equal("Unable to create configuration for 'Armagh::Support::HTTP' named 'a' because: \n    'nope://url' is not a valid HTTP or HTTPS URL.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_config_bad_url
    e = assert_raise(Configh::ConfigInitError) { Armagh::Support::HTTP.create_configuration( @config_store, 'b', { 'http' => { 'url' => 'bad url' }})}
    assert_equal("Unable to create configuration for 'Armagh::Support::HTTP' named 'b' because: \n    'bad url' is not a valid HTTP or HTTPS URL.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_config_bad_method
    e = assert_raise(Configh::ConfigInitError) {Armagh::Support::HTTP.create_configuration( @config_store, 'c', { 'http' => { 'url' => 'http://fake.url', 'method' => 'bad' }})}
    assert_equal("Unable to create configuration for 'Armagh::Support::HTTP' named 'c' because: \n    Group 'http' Parameter 'method': value is not one of the options (get,post)", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_no_proxy_user_or_pass
    expected_message = "Unable to create configuration for 'Armagh::Support::HTTP' named 'd' because: \n    In order to use proxy authentication, both proxy_username and proxy_password must be defined."

    config = { 
      'http' => { 'url' => 'http://fake.url', 
                  'proxy_url' => 'http://proxy.address',
                  'proxy_username' => 'proxy user',
                  'proxy_password' => Configh::DataTypes::EncodedString.from_plain_text( 'proxy pass')
      }
    } 
    
    [ 'proxy_username', 'proxy_password' ].each do |k|
      config1 = Marshal.load( Marshal.dump (config ))
      config1[ 'http' ].delete k
      e = assert_raise(Configh::ConfigInitError) { Armagh::Support::HTTP.create_configuration( @config_store, 'd', config1 )}
      assert_equal(expected_message, e.message)
      assert_equal @original_verbose, $VERBOSE 
    end
  end

  def test_bad_proxy
    config_values =  { 
      'http' => { 'url' => 'http://fake.url', 
                  'proxy_url' => 'bad proxy',
                  'proxy_username' => 'proxy user',
                  'proxy_password' => Configh::DataTypes::EncodedString.from_plain_text('proxy pass')
      }
    }
    e = assert_raise(Configh::ConfigInitError) {Armagh::Support::HTTP.create_configuration( @config_store, 'e', config_values )}
    assert_equal("Unable to create configuration for 'Armagh::Support::HTTP' named 'e' because: \n    'bad proxy' proxy is not a valid HTTP or HTTPS URL.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_config_bad_cert
    config_values =  { 
      'http' => { 'url' => 'http://fake.url', 
        'username'     => 'username',
        'password'     => Configh::DataTypes::EncodedString.from_plain_text('password'),
        'certificate'  => 'cert string',
        'key'          => 'key string',
        'key_password' => Configh::DataTypes::EncodedString.from_plain_text('key string')
       }
    }
    stub_request(:any, 'https://fake.url').with(basic_auth: [ 'username', 'password'])

    OpenSSL::X509::Certificate.expects(:new).with( 'cert string').raises(RuntimeError, 'BAD CERTIFICATE')
    OpenSSL::PKey::RSA.expects(:new).with('key string', 'key string').returns( :KEY )

    e = assert_raise(Configh::ConfigInitError){Armagh::Support::HTTP.create_configuration( @config_store, 'f', config_values )}
    assert_equal("Unable to create configuration for 'Armagh::Support::HTTP' named 'f' because: \n    Certificate Error: BAD CERTIFICATE.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_config_bad_key
    config_values = ( { 
      'http' => { 'url' => 'https://fake.url', 
        'username'     => 'username',
        'password'     => Configh::DataTypes::EncodedString.from_plain_text( 'password' ),
        'certificate'  => 'cert string',
        'key'          => 'key string',
        'key_password' => Configh::DataTypes::EncodedString.from_plain_text( 'key string' )
       }
    })
    stub_request(:any, 'https://fake.url').with(basic_auth: [ 'username', 'password'])

    OpenSSL::X509::Certificate.expects(:new).with( 'cert string').returns(:CERTIFICATE)
    OpenSSL::PKey::RSA.expects(:new).with('key string', 'key string').raises(RuntimeError, 'BAD KEY')

    e = assert_raise(Configh::ConfigInitError){Armagh::Support::HTTP.create_configuration( @config_store, 'g', config_values )}
    assert_equal("Unable to create configuration for 'Armagh::Support::HTTP' named 'g' because: \n    Key Error: BAD KEY.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_no_cert_or_key
    expected_message = "Unable to create configuration for 'Armagh::Support::HTTP' named 'h' because: \n    In order to use SSL certificate authentication, both certificate and key must be defined."

    config_values = { 
      'http' => { 'url' => 'http://fake.url', 
        'certificate'  => 'cert string',
        'key'          => 'key string'
       }
    }

    [ 'certificate', 'key' ].each do |k|
      config_values_bad = Marshal.load( Marshal.dump( config_values ))
      config_values_bad['http'].delete k
      e = assert_raise(Configh::ConfigInitError) { Armagh::Support::HTTP.create_configuration( @config_store, 'h', config_values_bad )}
      assert_equal(expected_message, e.message)
      assert_equal @original_verbose, $VERBOSE 
    end
  end

  def test_fetch_no_user_or_pass
    expected_message = "Unable to create configuration for 'Armagh::Support::HTTP' named 'j' because: \n    In order to use authentication, both username and password must be defined."

    config_values = { 
      'http' => { 'url' => 'http://fake.url', 
        'username'     => 'username',
        'password'     => Configh::DataTypes::EncodedString.from_plain_text('password')
       }
    }
    
    [ 'username', 'password' ].each do |k|
      config_values_bad = Marshal.load( Marshal.dump( config_values ))
      config_values_bad['http'].delete k
      e = assert_raise( Configh::ConfigInitError ) { Armagh::Support::HTTP.create_configuration( @config_store, 'j', config_values_bad )}
      assert_equal(expected_message, e.message)
      assert_equal @original_verbose, $VERBOSE 
    end
  end

  def test_fetch_bad_response
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'k', { 'http' => { 'url' => 'http://fake.url' }} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    stub_request(:any, 'http://fake.url').to_return(:status => [999, 'Invoked Error'], :body => '')
    e = assert_raise(Armagh::Support::HTTP::ConnectionError) {@http.fetch}
    assert_equal("Unexpected HTTP response from 'http://fake.url': 999 - Invoked Error.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_timeout
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'm', { 'http' => { 'url' => 'http://fake.url' }} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    stub_request(:any, 'http://fake.url').to_timeout
    e = assert_raise(Armagh::Support::HTTP::ConnectionError) {@http.fetch}
    assert_equal("HTTP response from 'http://fake.url' timed out.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_timeout_with_url_override
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'm', { 'http' => { 'url' => 'http://unused.url' }} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    stub_request(:any, 'http://fake.url').to_timeout
    e = assert_raise(Armagh::Support::HTTP::ConnectionError) {@http.fetch('http://fake.url')}
    assert_equal("HTTP response from 'http://fake.url' timed out.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end
  
  def test_fetch_configuration_error
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'n', { 'http' => { 'url' => 'http://fake.url' }} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    stub_request(:any, 'http://fake.url').to_raise(HTTPClient::ConfigurationError.new('Invoked Configuration Error'))
    e = assert_raise(Armagh::Support::HTTP::ConfigurationError) {@http.fetch}
    assert_equal("HTTP configuration error from 'http://fake.url': Invoked Configuration Error.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_unexpected_error
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'p', { 'http' => { 'url' => 'http://fake.url' }} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    stub_request(:any, 'http://fake.url').to_raise('Unexpected Error')
    e = assert_raise(Armagh::Support::HTTP::ConnectionError) {@http.fetch}
    assert_equal("Unexpected error requesting 'http://fake.url' - Unexpected Error.", e.message)
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_acceptable_uri_host_whitelist
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'auhw', { 'http' => { 'url' => 'http://fake.url', 'host_whitelist' => %w(fake.url subdomain.fake2.url)}} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    assert_false @http.acceptable_uri?('https://www.google.com')
    assert_true @http.acceptable_uri?('https://fake.url/something')
    assert_false @http.acceptable_uri?('https://bad.fake.url/something')
    assert_true @http.acceptable_uri?('https://subdomain.fake2.url/something')
    assert_false @http.acceptable_uri?('https://fake2.url/something')
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_acceptable_uri_host_blacklist
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'auhb', { 'http' => { 'url' => 'http://fake.url', 'host_blacklist' => %w(fake.url subdomain.fake2.url)}} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    assert_true @http.acceptable_uri?('https://www.google.com')
    assert_false @http.acceptable_uri?('https://fake.url/something')
    assert_true @http.acceptable_uri?('https://good.fake.url/something')
    assert_false @http.acceptable_uri?('https://subdomain.fake2.url/something')
    assert_true @http.acceptable_uri?('https://fake2.url/something')
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_acceptable_uri_host_whiteblack
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'auhwb', { 'http' => { 'url' => 'http://fake.url', 'host_blacklist' => ['fake.url'], 'host_whitelist' => ['fake.url']}} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    assert_false @http.acceptable_uri?('https://www.google.com')
    assert_false @http.acceptable_uri?('https://fake.url/something')
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_acceptable_uri_filetype_whitelist
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'autw', { 'http' => { 'url' => 'http://fake.url', 'filetype_whitelist' => %w(php html)}} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    assert_true @http.acceptable_uri?('https://www.google.com/index.php')
    assert_true @http.acceptable_uri?('https://www.google.com/index.html')
    assert_false @http.acceptable_uri?('https://www.google.com/index.json')
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_acceptable_uri_filetype_blacklist
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'autb', { 'http' => { 'url' => 'http://fake.url', 'filetype_blacklist' => %w(php html)}} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    assert_false @http.acceptable_uri?('https://www.google.com/index.php')
    assert_false @http.acceptable_uri?('https://www.google.com/index.html')
    assert_true @http.acceptable_uri?('https://www.google.com/index.json')
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_acceptable_uri_filetype_whiteblack
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'autwb', { 'http' => { 'url' => 'http://fake.url', 'filetype_blacklist' => %w(php html), 'filetype_whitelist' => %w(php html)}} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    assert_false @http.acceptable_uri?('https://www.google.com/index.php')
    assert_false @http.acceptable_uri?('https://www.google.com/index.html')
    assert_false @http.acceptable_uri?('https://www.google.com/index.json')
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_acceptable_mime_type_whitelist
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'autb', { 'http' => { 'url' => 'http://fake.url', 'mimetype_whitelist' => ['text/plain']}} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    assert_true @http.acceptable_mime_type?('text/plain')
    assert_false @http.acceptable_mime_type?('text/html')
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_acceptable_mime_type_blacklist
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'autb', { 'http' => { 'url' => 'http://fake.url', 'mimetype_blacklist' => %w(text/html)}} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    assert_true @http.acceptable_mime_type?('text/plain')
    assert_false @http.acceptable_mime_type?('text/html')
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_acceptable_mime_type_whiteblack
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'autb', { 'http' => { 'url' => 'http://fake.url', 'mimetype_whitelist' => %w(text/html), 'mimetype_blacklist' => %w(text/html)}} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    assert_false @http.acceptable_mime_type?('text/plain')
    assert_false @http.acceptable_mime_type?('text/html')
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_unacceptable_uri_blacklists
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httpget', { 'http' => {'url' => 'http://fake.url', 'host_blacklist' => ['fake.url'], 'filetype_blacklist' => ['xml']}})
    @http = Armagh::Support::HTTP::Connection.new(config)
    assert_raise(Armagh::Support::HTTP::SafeError.new("Unable to request from 'http://fake.url' due to whitelist/blacklist rules.")) { @http.fetch }
    assert_raise(Armagh::Support::HTTP::SafeError.new("Unable to request from 'http://something/bad.xml' due to whitelist/blacklist rules.")) { @http.fetch('http://something/bad.xml') }
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_get_mimes
    stub_request(:get, 'http://fake.url').to_return(headers: {'Content-Type' => 'text/plain; charset=ISO-8859-1'})
    stub_request(:get, 'http://fake2.url').to_return(headers: {'Content-Type' => 'text/html; charset=ISO-8859-1'})

    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httpget1', { 'http' => {'url' => 'http://fake.url', 'mimetype_blacklist' => ['text/plain']}})
    @http = Armagh::Support::HTTP::Connection.new(config)
    assert_raise(Armagh::Support::HTTP::SafeError.new("Unable to request from 'http://fake.url' due to whitelist/blacklist rules for mime type.")) { @http.fetch }
    assert_nothing_raised { @http.fetch('http://fake2.url') }

    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httpget2', { 'http' => {'url' => 'http://fake.url', 'mimetype_whitelist' => ['text/plain']}})
    @http = Armagh::Support::HTTP::Connection.new(config)
    assert_nothing_raised { @http.fetch }
    assert_raise(Armagh::Support::HTTP::SafeError.new("Unable to request from 'http://fake2.url' due to whitelist/blacklist rules for mime type.")) { @http.fetch('http://fake2.url') }
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_get_next_page_url
    next_url = 'http://www.example.com/2'

    content = "blah blah blah <a href='#{next_url}'>Next Page</a> and some more content"
    assert_equal(next_url, Armagh::Support::HTTP.get_next_page_url(content, 'http://www.example.com/1'))

    content = "blah blah blah <a href='#{next_url}'>Next Page</a> and some more content"
    assert_equal(next_url, Armagh::Support::HTTP.get_next_page_url(content, 'http://somewhere.else.com/1'))

    content = "blah blah blah <a href='#{next_url}'>Next</a> and some more content"
    assert_equal(next_url, Armagh::Support::HTTP.get_next_page_url(content, 'http://www.example.com/1'))

    content = "blah blah blah <a href='#{next_url}'><span>Next Page</span></a> and some more content"
    assert_equal(next_url, Armagh::Support::HTTP.get_next_page_url(content, 'http://somewhere.else.com/1'))

    content = "blah blah blah <div id='paginationWrapper'><span class='paginationNumbers'>Page 1 of 2</span><ul id='paginationList'><li><a class='nextPage' title='Next Page' href='#{next_url}'></a></li></ul></div>"
    assert_equal(next_url, Armagh::Support::HTTP.get_next_page_url(content, 'http://somewhere.else.com/1'))

    content = "blah blah blah <div id='paginationWrapper'><span class='paginationNumbers'>Page 1 of 2</span><ul id='paginationList'><li><a class='nextPage disabled' title='Next Page' href='#{next_url}'></a></li></ul></div>"
    assert_nil(Armagh::Support::HTTP.get_next_page_url(content, 'http://somewhere.else.com/1'))
    assert_equal @original_verbose, $VERBOSE 
  end

  def test_fetch_multiple_pages
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'disredir', { 'http' => { 'url' => 'http://fake.url', 'multiple_pages' => true }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    expected = ['part 1', 'part 2']
    stub_request(:get, 'http://fake.url').to_return(body: expected[0])
    stub_request(:get, 'http://fake.url2').to_return(body: expected[1])
    Armagh::Support::HTTP.stubs(:get_next_page_url).with(expected[0], 'http://fake.url').returns 'http://fake.url2'
    Armagh::Support::HTTP.stubs(:get_next_page_url).with(expected[1], 'http://fake.url2').returns nil

    result =  @http.fetch.collect{|r|r['body']}
    assert_equal(expected, result)
  end

  def test_fetch_no_multiple_pages
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'disredir', { 'http' => { 'url' => 'http://fake.url', 'multiple_pages' => false }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:get, 'http://fake.url').to_return(body: @expected_response)
    Armagh::Support::HTTP.expects(:get_next_page_url).never

    @http.fetch.collect{|r|r['body']}
  end

  def test_fetch_override_multiple_pages
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'disredir', { 'http' => { 'url' => 'http://fake.url', 'multiple_pages' => true }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:get, 'http://fake.url').to_return(body: @expected_response)
    Armagh::Support::HTTP.expects(:get_next_page_url).never

    @http.fetch(multiple_pages: false).collect{|r|r['body']}
  end

end
