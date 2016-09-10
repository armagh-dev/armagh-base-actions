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
    @config_store = []
  end

  def test_fetch_http_get
    stub_request(:get, 'http://fake.url').to_return(body: @expected_response)   
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httpget', { 'http' => { 'url' => 'http://fake.url' }})
    @http = Armagh::Support::HTTP::Connection.new( config )
    response = @http.fetch
    assert_equal(@expected_response, response['body'])
    assert_equal('200', response['head']['Status'])
    assert_equal(@expected_response.length.to_s, response['head']['Content-Length'])
  end

  def test_fetch_https_get
    stub_request(:get, 'https://fake.url').to_return(body: @expected_response)
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httpsget', { 'http' => { 'url' => 'https://fake.url' }})
    @http = Armagh::Support::HTTP::Connection.new( config )
    response = @http.fetch
    assert_equal(@expected_response, response['body'])
    assert_equal('200', response['head']['Status'])
    assert_equal(@expected_response.length.to_s, response['head']['Content-Length'])
  end

  def test_fetch_http_post
    stub_request(:post, 'http://fake.url').to_return(body: @expected_response)
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httppost', { 
      'http' => { 'url' => 'http://fake.url', 'method' => 'post'  }
    })
    @http = Armagh::Support::HTTP::Connection.new( config )
    response = @http.fetch
    assert_equal(@expected_response, response['body'])
    assert_equal('200', response['head']['Status'])
    assert_equal(@expected_response.length.to_s, response['head']['Content-Length'])
  end

  def test_fetch_https_post
    stub_request(:post, 'https://fake.url').to_return(body: @expected_response)
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'httpspost', { 
      'http' => { 'url' => 'https://fake.url', 'method' => 'post'  }
    })
    @http = Armagh::Support::HTTP::Connection.new( config )
    response = @http.fetch
    assert_equal(@expected_response, response['body'])
    assert_equal('200', response['head']['Status'])
    assert_equal(@expected_response.length.to_s, response['head']['Content-Length'])
  end

  def test_fetch_default_headers
    stub_request(:any, 'http://fake.url').with(headers: Armagh::Support::HTTP::Connection::DEFAULT_HEADERS)
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'defhead', { 
      'http' => { 'url' => 'http://fake.url', 'method' => 'post'  }
    })
    @http = Armagh::Support::HTTP::Connection.new( config )
    @http.fetch
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
  end

  def test_fetch_redirect
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'fetchredir', { 'http' => { 'url' => 'http://fake.url'}})
    @http = Armagh::Support::HTTP::Connection.new( config )
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: 'http://fake.url2'})
    stub_request(:any, 'http://fake.url2')
    @http.fetch
  end

  def test_fetch_too_many_redirect
    10.times do |i|
      stub_request(:any, "http://fake.url#{i}").to_return(:status => 302, :body => '', :headers => {Location: "http://fake.url#{i+1}"})
    end
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'tmdir', { 'http' => { 'url' => 'http://fake.url0'}})
    @http = Armagh::Support::HTTP::Connection.new( config )
    e = assert_raise(Armagh::Support::HTTP::RedirectError) {@http.fetch }
    assert_equal("Too many redirects from 'http://fake.url0'.", e.message)
  end

  def test_fetch_disabled_redirects
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'disredir', { 'http' => { 'url' => 'http://fake.url', 'follow_redirects' => false }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: 'http://fake.url2'})
    e = assert_raise(Armagh::Support::HTTP::RedirectError) {@http.fetch}
    assert_equal("Attempted to redirect from 'http://fake.url' but redirection is not allowed.", e.message)
  end

  def test_fetch_too_many_redirect_response
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'tmredres', { 'http' => { 'url' => 'http://fake.url' }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:any, 'http://fake.url').to_raise(HTTPClient::BadResponseError.new('retry count exceeded'))
    e = assert_raise(Armagh::Support::HTTP::RedirectError) {@http.fetch}
    assert_equal("Too many redirects from 'http://fake.url'.", e.message)
  end

  def test_https_to_http_redirect_chain
    config = Armagh::Support::HTTP.create_configuration( @config_store, 's2rred', { 'http' => { 'url' => 'http://fake.url', 'allow_https_to_http' => false }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: 'https://fake.url2'})
    stub_request(:any, 'https://fake.url2').to_return(:status => 302, :body => '', :headers => {Location: 'http://fake.url2'})
    stub_request(:any, 'http://fake.url2')
    assert_raise(Armagh::Support::HTTP::RedirectError.new("Attempted to redirect from an https resource to a no non-https resource while retrieving 'http://fake.url'.  Considering enabling allow_https_to_http.")){@http.fetch}
  end

  def test_https_to_http_redirect_chain_allowed
    config = Armagh::Support::HTTP.create_configuration( @config_store, 's2preall', { 'http' => { 'url' => 'http://fake.url', 'allow_https_to_http' => true }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: 'https://fake.url2'})
    stub_request(:any, 'https://fake.url2').to_return(:status => 302, :body => '', :headers => {Location: 'http://fake.url2'})
    stub_request(:any, 'http://fake.url2')
    @http.fetch
  end

  def test_https_to_http_redirect_chain_allowed_relative
    config = Armagh::Support::HTTP.create_configuration( @config_store, 's2prcar', { 'http' => { 'url' => 'http://fake.url', 'allow_https_to_http' => true }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:any, 'http://fake.url').to_return(:status => 302, :body => '', :headers => {Location: '/something'})
    stub_request(:any, 'http://fake.url/something')
    @http.fetch
  end

  def test_unknown_bad_response
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'badres', { 'http' => { 'url' => 'http://fake.url' }})
    @http = Armagh::Support::HTTP::Connection.new(config)
    stub_request(:any, 'http://fake.url').to_raise(HTTPClient::BadResponseError.new('bad response'))
    e = assert_raise(Armagh::Support::HTTP::ConnectionError) {@http.fetch}
    assert_equal("Unexpected error requesting 'http://fake.url' - bad response.", e.message)
  end

  def test_config_bad_protocol
    e = assert_raise(Configh::ConfigInitError) { Armagh::Support::HTTP.create_configuration( @config_store, 'a', { 'http' => { 'url' => 'nope://url' }})}
    assert_equal("Unable to create configuration Armagh::Support::HTTP a: 'nope://url' is not a valid HTTP or HTTPS URL.", e.message)
  end

  def test_config_bad_url
    e = assert_raise(Configh::ConfigInitError) { Armagh::Support::HTTP.create_configuration( @config_store, 'b', { 'http' => { 'url' => 'bad url' }})}
    assert_equal("Unable to create configuration Armagh::Support::HTTP b: 'bad url' is not a valid HTTP or HTTPS URL.", e.message)
  end

  def test_config_bad_method
    e = assert_raise(Configh::ConfigInitError) {Armagh::Support::HTTP.create_configuration( @config_store, 'c', { 'http' => { 'url' => 'http://fake.url', 'method' => 'bad' }})}
    assert_equal("Unable to create configuration Armagh::Support::HTTP c: Allowed HTTP Methods are post, get.  Was set to \'bad\'.", e.message)
  end

  def test_fetch_no_proxy_user_or_pass
    expected_message = 'Unable to create configuration Armagh::Support::HTTP d: In order to use proxy authentication, both proxy_username and proxy_password must be defined.'

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
    assert_equal("Unable to create configuration Armagh::Support::HTTP e: 'bad proxy' proxy is not a valid HTTP or HTTPS URL.", e.message)
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
    assert_equal('Unable to create configuration Armagh::Support::HTTP f: Certificate Error: BAD CERTIFICATE.', e.message)
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
    assert_equal('Unable to create configuration Armagh::Support::HTTP g: Key Error: BAD KEY.', e.message)
  end

  def test_fetch_no_cert_or_key
    expected_message = 'Unable to create configuration Armagh::Support::HTTP h: In order to use SSL certificate authentication, both certificate and key must be defined.'

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
    end
  end

  def test_fetch_no_user_or_pass
    expected_message = 'Unable to create configuration Armagh::Support::HTTP j: In order to use authentication, both username and password must be defined.'

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
    end
  end

  def test_fetch_bad_response
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'k', { 'http' => { 'url' => 'http://fake.url' }} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    stub_request(:any, 'http://fake.url').to_return(:status => [999, 'Invoked Error'], :body => '')
    e = assert_raise(Armagh::Support::HTTP::ConnectionError) {@http.fetch}
    assert_equal("Unexpected HTTP response from 'http://fake.url': 999 - Invoked Error.", e.message)
  end

  def test_fetch_timeout
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'm', { 'http' => { 'url' => 'http://fake.url' }} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    stub_request(:any, 'http://fake.url').to_timeout
    e = assert_raise(Armagh::Support::HTTP::ConnectionError) {@http.fetch}
    assert_equal("HTTP response from 'http://fake.url' timed out.", e.message)
  end

  def test_fetch_configuration_error
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'n', { 'http' => { 'url' => 'http://fake.url' }} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    stub_request(:any, 'http://fake.url').to_raise(HTTPClient::ConfigurationError.new('Invoked Configuration Error'))
    e = assert_raise(Armagh::Support::HTTP::ConfigurationError) {@http.fetch}
    assert_equal("HTTP configuration error from 'http://fake.url': Invoked Configuration Error.", e.message)
  end

  def test_fetch_unexpected_error
    config = Armagh::Support::HTTP.create_configuration( @config_store, 'p', { 'http' => { 'url' => 'http://fake.url' }} )
    @http = Armagh::Support::HTTP::Connection.new( config )
    stub_request(:any, 'http://fake.url').to_raise('Unexpected Error')
    e = assert_raise(Armagh::Support::HTTP::ConnectionError) {@http.fetch}
    assert_equal("Unexpected error requesting 'http://fake.url' - Unexpected Error.", e.message)
  end

end