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

require 'httpclient'

require_relative '../actions/parameter_definitions'

module Armagh
  module Support
    module HTTP
      class HTTPError          < StandardError; end
      class URLError           < HTTPError; end
      class RedirectError      < HTTPError; end
      class ConfigurationError < HTTPError; end
      class ConnectionError    < HTTPError; end
      class MethodError        < HTTPError; end

      extend Armagh::Actions::ParameterDefinitions

      POST = 'post'.freeze
      GET = 'get'.freeze

      METHODS = [POST, GET]

      define_parameter name: 'http_url',
                       description: 'URL to collect from',
                       type: String,
                       required: true,
                       prompt: 'http://www.example.com/page'

      define_parameter name: 'http_method',
                       description: 'HTTP Method to use for collection (get or post)',
                       type: String,
                       required: true,
                       prompt: 'get or post',
                       validation_callback: 'check_method',
                       default: 'get'

      define_parameter name: 'http_fields',
                       description: 'Fields to send as part of the request',
                       type: Hash,
                       required: false,
                       prompt: 'Hash of fields to send as part of the request'

      define_parameter name: 'http_headers',
                       description: 'HTTP Headers to send as part of the request',
                       type: Hash,
                       required: false,
                       prompt: 'Hash of headers to send as part of the request'

      define_parameter name: 'http_username',
                       description: 'Username for basic http authentication',
                       type: String,
                       required: false

      define_parameter name: 'http_password',
                       description: 'Password for basic http authentication',
                       type: EncodedString,
                       required: false

      define_parameter name: 'http_certificate',
                       description: 'Certificate for key based http authentication',
                       type: String,
                       required: false

      define_parameter name: 'http_key',
                       description: 'Key for key based http authentication',
                       type: String,
                       required: false

      define_parameter name: 'http_key_password',
                       description: 'Key Password for key based http authentication',
                       type: EncodedString,
                       required: false

      define_parameter name: 'http_proxy_url',
                       description: 'URL of the proxy server',
                       type: String,
                       required: false,
                       prompt: 'http://myproxy:8080'

      define_parameter name: 'http_proxy_username',
                       description: 'Username for proxy authentication',
                       type: String,
                       required: false

      define_parameter name: 'http_proxy_password',
                       description: 'Password for proxy authentication',
                       type: EncodedString,
                       required: false

      define_parameter name: 'http_follow_redirects',
                       description: 'Follow HTTP Redirects?',
                       type: Boolean,
                       required: true,
                       default: true

      define_parameter name: 'allow_https_to_http',
                       description: 'Allow redirection from https to http.  Enabling this may be a security concern.',
                       type: Boolean,
                       required: true,
                       default: false

      def check_method(proposed_method)
        METHODS.include?(proposed_method.downcase) ? nil : "Allowed HTTP Methods are #{METHODS}.  Was set to '#{proposed_method}'."
      end

      def custom_validation
        # @parameters expected to be defined in class utilizing this module
        messages = []

        if (@parameters['http_proxy_username'] || @parameters['http_proxy_password']) && !(@parameters['http_proxy_username'] && @parameters['http_proxy_password'])
          messages << 'In order to use proxy authentication, both user and pass must be defined.'
        end

        if (@parameters['http_certificate'] || @parameters['http_key']) && !(@parameters['http_certificate'] && @parameters['http_key'])
          messages << 'In order to use SSL certificate authentication, both cert and key must be defined.'
        end

        if (@parameters['http_username'] || @parameters['http_password']) && !(@parameters['http_username'] && @parameters['http_password'])
          messages <<  'In order to use authentication, both user and pass must be defined.'
        end
        if messages.empty?
          nil
        else
          messages.join(', ')
        end
      end

      class Connection
        DEFAULT_HEADERS = {
            # User agent string to use, if not defined in a header.  Taken from https://techblog.willshouse.com/2012/01/03/most-common-user-agents/ on Jun 2, 2016
            'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'.freeze
        }.freeze

        COOKIE_STORE = File.join('', 'tmp', 'armagh_cookie.dat').freeze

        def initialize(follow_redirects: true, allow_https_to_http: false)
          @client = HTTPClient.new # Don't add agent to the new call as library details are appended to the end
          @client.follow_redirect_count = 0 unless follow_redirects
          @client.set_cookie_store COOKIE_STORE
          @client.redirect_uri_callback = method(:alternative_uri_callback) if allow_https_to_http
        end

        # Fetches the content of a given URL.
        # @param url [String] the url to request
        # @param method [HTTP::POST, HTTP::GET]
        # @param fields [Hash] fields to include in the request
        # @param proxy [Hash] proxy configuration.  Available fields are: url, user, pass
        # @param auth [Hash] authentication configuration.  Available fields are: cert, key, key_pass, user, pass
        # @param headers [Hash] headers to include in the request
        # @raise [URLError] an error with the url scheme
        # @raise [ConfigurationError] an error with configuration
        # @raise [MethodError] an unknown method type was attempted.  Valid types are HTTP::POST and HTTP::GET
        # @raise [RedirectError] a problem with redirection
        # @raise [ConnectionError] an error with the http connection
        # @return [Hash] response containing the response body in the 'body' field and response header in the 'head' field
        def fetch(url, method: GET, fields: {}, proxy: {}, auth: {}, headers: {})
          url.strip!
          method = method.downcase
          raise HTTP::URLError, "'#{url}' is not a valid HTTP or HTTPS URL." unless URI.parse(url).is_a? URI::HTTP

          set_proxy(proxy)
          set_auth(url, auth)

          response = request(url, method, fields, DEFAULT_HEADERS.merge(headers))
          @client.save_cookie_store
          response
        rescue URI::InvalidURIError
          raise HTTP::URLError, "'#{url}' is not a valid HTTP or HTTPS URL."
        end

        private def set_proxy(proxy)
          @client.proxy = proxy['url'] if proxy['url']
          if proxy['user'] && proxy['pass'] && proxy['url']
            @client.set_proxy_auth(proxy['user'], proxy['pass'])
          elsif proxy['user'] || proxy['pass']
            raise HTTP::ConfigurationError, 'In order to use proxy authentication, both user and pass must be defined'
          end
        rescue => e
          raise HTTP::ConfigurationError, "Unable to set proxy.  #{e.message}."
        end

        private def set_auth(url, auth)
          if auth['cert'] && auth['key']
            begin
              @client.ssl_config.client_cert = OpenSSL::X509::Certificate.new(auth['cert'])
            rescue => e
              raise HTTP::ConfigurationError, "Certificate Error: #{e.message}."
            end

            begin
              @client.ssl_config.client_key = OpenSSL::PKey::RSA.new(auth['key'], auth['key_pass'])
            rescue => e
              raise HTTP::ConfigurationError, "Key Error: #{e.message}."
            end
          elsif auth['cert'] || auth['key']
            raise HTTP::ConfigurationError, 'In order to use SSL certificate authentication, both cert and key must be defined.'
          end

          if auth['user'] && auth['pass']
            @client.set_auth(url, auth['user'], auth['pass'])
            @client.force_basic_auth = true
          elsif auth['user'] || auth['pass']
            raise HTTP::ConfigurationError, 'In order to use authentication, both user and pass must be defined.'
          end
        rescue => e
          raise HTTP::ConfigurationError, "Unable to set authentication.  #{e.message}"
        end

        private def request(url, method, fields, headers)
          case method
            when GET
              response = @client.get(url, query: fields, header: headers, follow_redirect: true)
            when POST
              response = @client.post(url, body: fields, header: headers, follow_redirect: true)
            else
              raise HTTP::MethodError, "Unknown HTTP method '#{method}'.  Expected 'get' or 'post'."
          end

          if response.ok?
            {'head' => header_to_hash(response.header), 'body' => response.content}
          else
            raise HTTP::ConnectionError, "Unexpected HTTP response from '#{url}': #{response.status} - #{response.reason}."
          end
        rescue HTTPClient::TimeoutError # KEEP
          raise HTTP::ConnectionError, "HTTP response from '#{url}' timed out."
        rescue HTTPClient::ConfigurationError => e # KEEP
          raise HTTP::ConfigurationError, "HTTP configuration error from '#{url}': #{e.message}."
        rescue HTTPClient::BadResponseError => e
          if e.message == 'retry count exceeded'
            if @client.follow_redirect_count == 0
              raise HTTP::RedirectError, "Attempted to redirect from '#{url}' but redirection is not allowed."
            else
              raise HTTP::RedirectError, "Too many redirects from '#{url}'."
            end
          elsif e.message == 'redirecting to non-https resource'
            raise HTTP::RedirectError, "Attempted to redirect from an https resource to a no non-https resource while retrieving '#{url}'.  Considering enabling allow_https_to_http."
          else
            raise HTTP::ConnectionError, "Unexpected error requesting '#{url}' - #{e.message}."
          end
        rescue HTTP::HTTPError
          raise
        rescue => e
          raise HTTP::ConnectionError, "Unexpected error requesting '#{url}' - #{e.message}."
        end

        private def header_to_hash(head)
          hash = {}
          head.dump.split("\r\n").each do |row|
            key, value = row.split ': ', 2
            hash[key] = value.strip
          end
          hash
        end

        # The default HTTP Client redirect callback does not handle http -> https.  This is very close to the default without that check.
        private def alternative_uri_callback(uri, res)
          newuri = HTTPClient::Util.urify(res.header['location'][0])
          if !@client.http?(newuri) && !@client.https?(newuri)
            newuri = uri + newuri
          end
          newuri
        end
      end
    end
  end
end
