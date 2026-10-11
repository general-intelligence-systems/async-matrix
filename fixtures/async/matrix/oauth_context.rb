# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/http/internet"

require "protocol/url/encoding"

require_relative "client_context"

module Async
  module Matrix
    # The user the OAuth rig registers.
    OAUTH_USERNAME = ENV.fetch("MATRIX_OAUTH_USERNAME", "oauthtester")

    OAUTH_PASSWORD = ENV.fetch("MATRIX_OAUTH_PASSWORD", "password")

    # Where the rig sends an authorization code back to.
    OAUTH_REDIRECT_URI = "http://127.0.0.1/"

    # Walks the authorization server's own pages, as a browser would.
    #
    # The user's consent is the one part of the flow a client cannot perform.
    class Browser
      # The hidden field every form on the authorization server carries.
      CSRF = /name="csrf" value="([^"]+)"/

      def initialize
        @internet = ::Async::HTTP::Internet.new
        @cookies = {}
      end

      def close
        @internet.close
      end

      # Follow redirects from the given URL until a page is returned.
      #
      # @parameter url [String] where to start.
      # @returns [Tuple(String, String)] the URL settled on, and its body.
      def open(url)
        while true
          response = self.request("GET", url)

          location = response.headers["location"]

          unless location
            body = response.read

            break [url, body]
          end

          response.close
          url = self.absolute(url, location)
        end
      end

      # Submit a form, and report where the server sent us.
      #
      # @parameter url [String] where to post.
      # @parameter form [Hash] the fields to send.
      # @returns [String] the location the server redirected to.
      def submit(url, **form)
        response = self.request("POST", url, ::Protocol::URL::Encoding.encode(form))

        location = response.headers["location"]

        unless location
          body = response.read

          raise "The authorization server did not redirect from #{url}: #{response.status} #{body}"
        end

        response.close

        self.absolute(url, location)
      end

      # The CSRF token a page carries.
      #
      # @parameter body [String] the page.
      # @returns [String] the token.
      def csrf(body)
        body[CSRF, 1]
      end

      # Make a request, carrying whatever cookies the server has set.
      #
      # @parameter method [String] the HTTP method.
      # @parameter url [String] where to send it.
      # @parameter body [String | nil] a form encoded body, if any.
      # @returns [Protocol::HTTP::Response] the response.
      private def request(method, url, body = nil)
        headers = {}

        unless @cookies.empty?
          headers["cookie"] = @cookies.map{|name, value| "#{name}=#{value}"}.join("; ")
        end

        if body
          headers["content-type"] = "application/x-www-form-urlencoded"
        end

        response = @internet.call(method, url, headers, body ? [body] : nil)

        self.remember(response)

        response
      end

      # Remember the cookies a response set.
      #
      # @parameter response [Protocol::HTTP::Response] the response to read.
      # @returns [Nil] nothing.
      private def remember(response)
        Array(response.headers["set-cookie"]).each do |header|
          name, value = header.split(";", 2).first.split("=", 2)

          @cookies[name] = value
        end

        nil
      end

      # Resolve a location against the URL it came from.
      #
      # @parameter url [String] the URL the response came from.
      # @parameter location [String] the location header.
      # @returns [String] an absolute URL.
      private def absolute(url, location)
        if location.start_with?("http")
          location
        else
          endpoint = ::Async::HTTP::Endpoint.parse(url)

          "#{endpoint.scheme}://#{endpoint.authority}#{location}"
        end
      end
    end

    OAuthContext = Sus::Shared("an oauth client") do
      include Sus::Fixtures::Async::ReactorContext

      let(:unauthenticated) {Async::Matrix::ClientServer::Client[Async::Matrix::TEST_VERSION].open(Async::Matrix::OAUTH_HOMESERVER)}

      # Authorize a client by logging in and consenting, as the user would in a browser.
      #
      # @parameter authorization [Async::Matrix::OAuth::Authorization] the authorization in progress.
      # @returns [Hash] the `code` and `state` the redirect carried.
      def consent_to(authorization)
        browser = Browser.new

        login_url, login_page = browser.open(authorization.url)

        consent_url = browser.submit(login_url,
          csrf: browser.csrf(login_page),
          username: Async::Matrix::OAUTH_USERNAME,
          password: Async::Matrix::OAUTH_PASSWORD,
        )

        _, consent_page = browser.open(consent_url)

        redirected = browser.submit(consent_url, csrf: browser.csrf(consent_page))

        ::Protocol::URL::Encoding.decode(redirected.split("?", 2).last.split("#", 2).first)
      ensure
        browser&.close
      end
    end
  end
end
