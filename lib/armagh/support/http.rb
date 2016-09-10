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
require 'configh'

module Armagh
  module Support
    module HTTP
      include Configh::Configurable
      
      class HTTPError          < StandardError; end
      class URLError           < HTTPError; end
      class RedirectError      < HTTPError; end
      class ConfigurationError < HTTPError; end
      class ConnectionError    < HTTPError; end
      class MethodError        < HTTPError; end

      POST = 'post'.freeze
      GET = 'get'.freeze

      METHODS = [POST, GET]

      define_parameter name: 'url',                 description: 'URL to collect from',                             type: 'populated_string', required: true,  prompt: 'http://www.example.com/page'
      define_parameter name: 'method',              description: 'HTTP Method to use for collection (get or post)', type: 'populated_string', required: true,  prompt: 'get or post', default: 'get'
      define_parameter name: 'fields',              description: 'Fields to send as part of the request',           type: 'hash',               required: false, prompt: 'Hash of fields to send as part of the request', default: {}
      define_parameter name: 'headers',             description: 'HTTP Headers to send as part of the request',     type: 'hash',               required: false, prompt: 'Hash of headers to send as part of the request', default: {}
      define_parameter name: 'username',            description: 'Username for basic http authentication',          type: 'string',           required: false
      define_parameter name: 'password',            description: 'Password for basic http authentication',          type: 'encoded_string',   required: false
      define_parameter name: 'certificate',         description: 'Certificate for key based http authentication',   type: 'string',           required: false
      define_parameter name: 'key',                 description: 'Key for key based http authentication',           type: 'string',           required: false
      define_parameter name: 'key_password',        description: 'Key Password for key based http authentication',  type: 'encoded_string',   required: false
      define_parameter name: 'proxy_url',           description: 'URL of the proxy server',                         type: 'string',           required: false, prompt: 'http://myproxy:8080'
      define_parameter name: 'proxy_username',      description: 'Username for proxy authentication',               type: 'string',           required: false
      define_parameter name: 'proxy_password',      description: 'Password for proxy authentication',               type: 'encoded_string',   required: false
      define_parameter name: 'follow_redirects',    description: 'Follow HTTP Redirects?',                         type: 'boolean',          required: true,  default: true
      define_parameter name: 'allow_https_to_http', description: 'Allow redirection from https to http.  Enabling this may be a security concern.', type: 'boolean', required: true, default: false

      define_group_validation_callback callback_class: Armagh::Support::HTTP, callback_method: :validate
      
      def HTTP.validate( candidate_config )

        hc = candidate_config.http        
        messages = []
        
        messages << validate_url( hc.url )
        messages << validate_method( hc.method )
          if ( hc.proxy_username || hc.proxy_password ) && !(hc.proxy_username && hc.proxy_password )
          messages << 'In order to use proxy authentication, both proxy_username and proxy_password must be defined.'
        end
        if (hc.certificate || hc.key) && !(hc.certificate && hc.key)
          messages << 'In order to use SSL certificate authentication, both certificate and key must be defined.'
        end
        if hc.certificate && hc.key
          begin
            OpenSSL::X509::Certificate.new( hc.certificate )
          rescue => e
            messages << "Certificate Error: #{e.message}."
          end
        end
        if hc.certificate && hc.key && hc.key_password
          begin
            OpenSSL::PKey::RSA.new( hc.key, hc.key_password.plain_text )
          rescue => e
            messages << "Key Error: #{e.message}."
          end
        end
        if (hc.username|| hc.password) && !(hc.username && hc.password)
          messages <<  'In order to use authentication, both username and password must be defined.'
        end
        if hc.proxy_url
          begin
            raise unless URI.parse(hc.proxy_url).is_a? URI::HTTP
          rescue
            messages << "'#{hc.proxy_url}' proxy is not a valid HTTP or HTTPS URL."
          end
        end
        messages.compact!
        if messages.empty?
         return  nil
        else
          return messages.join(', ')
        end
      end
      
      def HTTP.validate_url( candidate_url )
        message = nil
        begin
          raise unless URI.parse(candidate_url).is_a? URI::HTTP   # weird structure because error may be raised or thru is_a fail
        rescue
          message = "'#{candidate_url}' is not a valid HTTP or HTTPS URL."
        end
        message
      end
      
      def HTTP.validate_method( candidate_method )
        "Allowed HTTP Methods are #{METHODS.join(", ")}.  Was set to '#{candidate_method}'." unless METHODS.include?(candidate_method.downcase)
      end
      
      def HTTP.validate_fields( candidate_fields )
        "Fields must be a hash" unless candidate_fields.is_a?( Hash )
      end
      

      class Connection
        DEFAULT_HEADERS = {
            # User agent string to use, if not defined in a header.  Taken from https://techblog.willshouse.com/2012/01/03/most-common-user-agents/ on Jun 2, 2016
            'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'.freeze
        }.freeze

        COOKIE_STORE = File.join('', 'tmp', 'armagh_cookie.dat').freeze

        def initialize( config )
          
          raise ConfigurationError, "Connection must be initialized with a Configh configuration object" unless config.is_a?( Configh::Configuration )
          @cfg     = config.http
          @url     = @cfg.url.strip
          @method  = @cfg.method.downcase
          @headers = DEFAULT_HEADERS.merge @cfg.headers
          
          @client = HTTPClient.new # Don't add agent to the new call as library details are appended to the end
          @client.follow_redirect_count = 0 unless @cfg.follow_redirects
          @client.set_cookie_store COOKIE_STORE
          @client.redirect_uri_callback = method(:alternative_uri_callback) if @cfg.allow_https_to_http
          
          set_proxy
          set_auth
        end

        # Fetches the content of a given URL.
        def fetch( override_url = nil, override_method = nil, override_fields = nil)
      
          url = override_url || @url
          method = override_method || @cfg.method
          fields = override_fields || @cfg.fields
          
          override_error_messages = []
          override_error_messages << HTTP.validate_url( url )
          override_error_messages << HTTP.validate_method( method )
          override_error_messages << HTTP.validate_fields( fields )
          override_error_messages.compact!
          
          unless override_error_messages.empty?
            raise ConfigurationError, "code overrode parameters for fetch with bad values: #{ override_error_messages.join(', ')}"
          end

          # verbose toggle because httpclient internally uses Kernel#warn
          old_verbose = $VERBOSE = nil          
          response = request( url, method, fields )

          @client.save_cookie_store
          $VERBOSE = old_verbose
          response
        rescue URI::InvalidURIError
          raise HTTP::URLError, "'#{@url}' is not a valid HTTP or HTTPS URL."
        end

        private def set_proxy
          @client.proxy = @cfg.proxy_url if @cfg.proxy_url
          if @cfg.proxy_username && @cfg.proxy_password && @cfg.proxy_url
            @client.set_proxy_auth( @cfg.proxy_username, @cfg.proxy_password.plain_text )
          end
        end
  
        private def set_auth
          if @cfg.certificate && @cfg.key 
            begin
              @client.ssl_config.client_cert = OpenSSL::X509::Certificate.new( @cfg.certificate )
            rescue => e
              raise HTTP::ConfigurationError, "Certificate Error: #{e.message}."
            end

            begin
              @client.ssl_config.client_key = OpenSSL::PKey::RSA.new( @cfg.key, @cfg.key_password.plain_text )
            rescue => e
              raise HTTP::ConfigurationError, "Key Error: #{e.message}."
            end
          end

          if @cfg.username && @cfg.password 
            @client.set_auth(@url, @cfg.username, @cfg.password.plain_text)
            @client.force_basic_auth = true
          end
        rescue => e
          raise HTTP::ConfigurationError, "Unable to set authentication.  #{e.message}"
        end

        private def request( url, method, fields )
          
          case method
            when GET
              response = @client.get(url, query: fields, header: @headers, follow_redirect: @cfg.follow_redirects)
            when POST
              response = @client.post(url, body: fields, header: @headers, follow_redirect: @cfg.follow_redirects)
          end

          if response.ok?
            {'head' => header_to_hash(response.header), 'body' => response.content}
          else
            if response.status == 302
              raise HTTP::RedirectError, "Attempted to redirect from '#{@url}' but redirection is not allowed."
            else
              raise HTTP::ConnectionError, "Unexpected HTTP response from '#{@url}': #{response.status} - #{response.reason}."
            end
          end
        rescue HTTPClient::TimeoutError # KEEP
          raise HTTP::ConnectionError, "HTTP response from '#{@url}' timed out."
        rescue HTTPClient::ConfigurationError => e # KEEP
          raise HTTP::ConfigurationError, "HTTP configuration error from '#{@url}': #{e.message}."
        rescue HTTPClient::BadResponseError => e
          if e.message == 'retry count exceeded'
            if @client.follow_redirect_count == 0
              raise HTTP::RedirectError, "Attempted to redirect from '#{@url}' but redirection is not allowed."
            else
              raise HTTP::RedirectError, "Too many redirects from '#{@url}'."
            end
          elsif e.message == 'redirecting to non-https resource'
            raise HTTP::RedirectError, "Attempted to redirect from an https resource to a no non-https resource while retrieving '#{@url}'.  Considering enabling allow_https_to_http."
          else
            raise HTTP::ConnectionError, "Unexpected error requesting '#{@url}' - #{e.message}."
          end
        rescue HTTP::HTTPError
          raise
        rescue => e
          raise HTTP::ConnectionError, "Unexpected error requesting '#{@url}' - #{e.message}."
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
