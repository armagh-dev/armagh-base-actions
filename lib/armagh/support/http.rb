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

require 'httpclient'
require 'configh'
require_relative 'encoding'
require_relative '../support/xml/parser'

module Armagh
  module Support
    module HTTP
      include Configh::Configurable

      class HTTPError < StandardError; end
      class URLError < HTTPError; end
      class RedirectError < HTTPError; end
      class ConfigurationError < HTTPError; end
      class ConnectionError < HTTPError; end
      class MethodError < HTTPError; end
      class SafeError < HTTPError; end

      POST = 'post'.freeze
      GET = 'get'.freeze

      METHODS = [POST, GET]

      define_parameter name: 'url', description: 'URL to collect from', type: 'populated_string', required: true, prompt: 'http://www.example.com:8080/page'
      define_parameter name: 'method', description: 'HTTP Method to use for collection (get or post)', type: 'populated_string', required: true, prompt: 'get or post', default: 'get'
      define_parameter name: 'fields', description: 'Fields to send as part of the request', type: 'hash', required: false, prompt: 'Hash of fields to send as part of the request', default: {}
      define_parameter name: 'headers', description: 'HTTP Headers to send as part of the request', type: 'hash', required: false, prompt: 'Hash of headers to send as part of the request', default: {}
      define_parameter name: 'username', description: 'Username for basic http authentication', type: 'string', required: false
      define_parameter name: 'password', description: 'Password for basic http authentication', type: 'encoded_string', required: false
      define_parameter name: 'certificate', description: 'Certificate for key based http authentication', type: 'string', required: false
      define_parameter name: 'key', description: 'Key for key based http authentication', type: 'string', required: false
      define_parameter name: 'key_password', description: 'Key Password for key based http authentication', type: 'encoded_string', required: false
      define_parameter name: 'proxy_url', description: 'URL of the proxy server', type: 'string', required: false, prompt: 'http://myproxy:8080'
      define_parameter name: 'proxy_username', description: 'Username for proxy authentication', type: 'string', required: false
      define_parameter name: 'proxy_password', description: 'Password for proxy authentication', type: 'encoded_string', required: false
      define_parameter name: 'follow_redirects', description: 'Follow HTTP Redirects?', type: 'boolean', required: true, default: true
      define_parameter name: 'allow_https_to_http', description: 'Allow redirection from https to http.  Enabling this may be a security concern.', type: 'boolean', required: true, default: false
      define_parameter name: 'host_whitelist', description: 'List of hostnames that collection is allowed from', type: 'string_array', required: false, prompt: 'subdomain.domain.com'
      define_parameter name: 'host_blacklist', description: 'List of hostnames that collection is not allowed from', type: 'string_array', required: false, prompt: 'subdomain.domain.com'
      define_parameter name: 'filetype_whitelist', description: 'List of file types that collection is allowed to collect', type: 'string_array', required: false, prompt: '[txt, pdf]'
      define_parameter name: 'filetype_blacklist', description: 'List of file types that collection is not allowed to collect', type: 'string_array', required: false, prompt: '[txt, pdf]'
      define_parameter name: 'mimetype_whitelist', description: 'List of mime types that collection is allowed to collect', type: 'string_array', required: false, prompt: '[text/html, text/plain]'
      define_parameter name: 'mimetype_blacklist', description: 'List of mime types that collection is not allowed to collect', type: 'string_array', required: false, prompt: '[text/html, text/plain]'
      define_parameter name: 'multiple_pages', description: 'Collect multiple pages', type: 'boolean', required: true, default: true
      define_parameter name: 'max_pages', description: 'Maximum number of pages to collect when collecting multiple', type: 'positive_integer', required: true, default: 10


      define_group_validation_callback callback_class: Armagh::Support::HTTP, callback_method: :validate

      def HTTP.validate(candidate_config)
        hc = candidate_config.http
        messages = []

        messages << validate_url(hc.url)
        messages << validate_method(hc.method)
        if (hc.proxy_username || hc.proxy_password) && !(hc.proxy_username && hc.proxy_password)
          messages << 'In order to use proxy authentication, both proxy_username and proxy_password must be defined.'
        end
        if (hc.certificate || hc.key) && !(hc.certificate && hc.key)
          messages << 'In order to use SSL certificate authentication, both certificate and key must be defined.'
        end
        if hc.certificate && hc.key
          begin
            OpenSSL::X509::Certificate.new(hc.certificate)
          rescue => e
            messages << "Certificate Error: #{e.message}."
          end
        end
        if hc.certificate && hc.key && hc.key_password
          begin
            OpenSSL::PKey::RSA.new(hc.key, hc.key_password.plain_text)
          rescue => e
            messages << "Key Error: #{e.message}."
          end
        end
        if (hc.username|| hc.password) && !(hc.username && hc.password)
          messages << 'In order to use authentication, both username and password must be defined.'
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
          return nil
        else
          return messages.join(', ')
        end
      end

      def HTTP.validate_url(candidate_url)
        message = nil
        begin
          raise unless URI.parse(candidate_url).is_a? URI::HTTP # weird structure because error may be raised or thru is_a fail
        rescue
          message = "'#{candidate_url}' is not a valid HTTP or HTTPS URL."
        end
        message
      end

      def HTTP.validate_method(candidate_method)
        "Allowed HTTP Methods are #{METHODS.join(", ")}.  Was set to '#{candidate_method}'." unless METHODS.include?(candidate_method.downcase)
      end

      def HTTP.validate_fields(candidate_fields)
        "Fields must be a hash" unless candidate_fields.is_a?(Hash)
      end

      def HTTP.extract_type(header)
        info = {}
        type_str = header['Content-Type']
        return info if type_str.nil? || type_str.empty?

        type_details = type_str.split(';')
        info['type'] = type_details.first

        type_details[1..-1].each do |detail|
          detail.strip!
          if detail.start_with?('charset=')
            info['encoding'] = detail.sub('charset=', '')
          end
        end
        info
      end

      def HTTP.get_next_page_url(page_content, source_url)
        page_content.scan(/<a.*?href.*?<\/a>/im) do |h_link|
          down = h_link.downcase
          if down.include?('next')
            link = down[/href=['"](.+?)['"]/m, 1]
            if !down.include?('disable') && (link.gsub(/\d/, '').include?(source_url.gsub(/\d/, '')) || down.include?('page'))
              return link
            end
          end
        end

        nil
      end

      class Connection
        DEFAULT_HEADERS = {
          # User agent string to use, if not defined in a header.  Taken from https://techblog.willshouse.com/2012/01/03/most-common-user-agents/ on Jan 25, 2017
          'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36'.freeze
        }.freeze

        COOKIE_STORE = File.join('', 'tmp', 'armagh_cookie.dat').freeze

        def initialize(config, logger: nil)

          raise ConfigurationError, 'Connection must be initialized with a Configh configuration object' unless config.is_a?(Configh::Configuration)
          @config = config.http
          @url = @config.url.strip
          @method = @config.method.downcase
          @headers = DEFAULT_HEADERS.merge @config.headers
          @logger = logger

          @client = HTTPClient.new # Don't add agent to the new call as library details are appended to the end
          @client.follow_redirect_count = 0 unless @config.follow_redirects
          @client.set_cookie_store COOKIE_STORE

          if @config.allow_https_to_http
            @client.redirect_uri_callback = method(:unsafe_uri_callback)
          else
            @client.redirect_uri_callback = method(:safe_uri_callback)
          end

          set_proxy
          set_auth
        end

        # Fetches the content of a given URL.
        def fetch(override_url = nil, override_method = nil, override_fields = nil)
          url = override_url || @url
          method = override_method || @config.method
          fields = override_fields || @config.fields

          override_error_messages = []
          override_error_messages << HTTP.validate_url(url)
          override_error_messages << HTTP.validate_method(method)
          override_error_messages << HTTP.validate_fields(fields)
          override_error_messages.compact!

          unless override_error_messages.empty?
            raise ConfigurationError, "code overrode parameters for fetch with bad values: #{ override_error_messages.join(', ')}"
          end

          # verbose toggle because httpclient internally uses Kernel#warn
          old_verbose = $VERBOSE
          $VERBOSE = nil
          start = Time.now
          response = request(url, method, fields)
          @logger.debug "Fetched #{url} in #{Time.now - start} seconds" if @logger

          @client.save_cookie_store
          response
        rescue URI::InvalidURIError
          raise HTTP::URLError, "'#{url}' is not a valid HTTP or HTTPS URL."
        ensure
          $VERBOSE = old_verbose
        end

        def acceptable_uri?(uri)
          uri = HTTPClient::Util.urify(uri)
          hostname = uri.hostname
          extname = File.extname(uri.to_s).sub('.', '')

          return false if @config.host_whitelist && !@config.host_whitelist.include?(hostname)
          return false if @config.host_blacklist && @config.host_blacklist.include?(hostname)
          return false if @config.filetype_whitelist && !@config.filetype_whitelist.include?(extname)
          return false if @config.filetype_blacklist && @config.filetype_blacklist.include?(extname)
          true
        end

        def acceptable_mime_type?(type)
          return false if @config.mimetype_whitelist && !@config.mimetype_whitelist.include?(type)
          return false if @config.mimetype_blacklist && @config.mimetype_blacklist.include?(type)
          true
        end

        private def set_proxy
          @client.proxy = @config.proxy_url if @config.proxy_url
          if @config.proxy_username && @config.proxy_password && @config.proxy_url
            @client.set_proxy_auth(@config.proxy_username, @config.proxy_password.plain_text)
          end
        end

        private def set_auth
          if @config.certificate && @config.key
            begin
              @client.ssl_config.client_cert = OpenSSL::X509::Certificate.new(@config.certificate)
            rescue => e
              raise HTTP::ConfigurationError, "Certificate Error: #{e.message}."
            end

            begin
              @client.ssl_config.client_key = OpenSSL::PKey::RSA.new(@config.key, @config.key_password.plain_text)
            rescue => e
              raise HTTP::ConfigurationError, "Key Error: #{e.message}."
            end
          end

          if @config.username && @config.password
            @client.set_auth(@url, @config.username, @config.password.plain_text)
            @client.force_basic_auth = true
          end
        rescue => e
          raise HTTP::ConfigurationError, "Unable to set authentication.  #{e.message}"
        end

        private def request(url, method, fields, pages = [])
          raise SafeError, "Unable to request from '#{url}' due to whitelist/blacklist rules." unless acceptable_uri? url

          case method
            when GET
              response = @client.get(url, query: fields, header: @headers, follow_redirect: @config.follow_redirects)
            when POST
              response = @client.post(url, body: fields, header: @headers, follow_redirect: @config.follow_redirects)
          end

          header_hash = header_to_hash(response.header)

          raise SafeError, "Unable to request from '#{url}' due to whitelist/blacklist rules for mime type." unless acceptable_mime_type?(HTTP.extract_type(header_hash)['type'])

          if response.ok?
            response_text = Support::Encoding.fix_encoding(response.content)

            pages << {'head' => header_hash, 'body' => response_text}

            if @config.multiple_pages && pages.length < @config.max_pages
              next_url = HTTP.get_next_page_url(response_text, url)
              request(next_url, method, fields, pages) if next_url
            end

            pages
          else
            if response.status == 302
              raise HTTP::RedirectError, "Attempted to redirect from '#{url}' but redirection is not allowed."
            else
              raise HTTP::ConnectionError, "Unexpected HTTP response from '#{url}': #{response.status} - #{response.reason}."
            end
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

        private def safe_uri_callback(uri, res)
          newuri = @client.default_redirect_uri_callback(uri, res)
          raise SafeError, "Unable to redirect to '#{newuri}' due to whitelist/blacklist rules." unless acceptable_uri? newuri
          newuri
        end

        # The default HTTP Client redirect callback does not handle http -> https.  This is very close to the default without that check.
        private def unsafe_uri_callback(uri, res)
          newuri = HTTPClient::Util.urify(res.header['location'][0])
          if !@client.http?(newuri) && !@client.https?(newuri)
            newuri = uri + newuri
          end
          raise SafeError, "Unable to redirect to '#{newuri}' due to whitelist/blacklist rules." unless acceptable_uri? newuri
          newuri
        end
      end
    end
  end
end
