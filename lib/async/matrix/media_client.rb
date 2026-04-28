# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/http/internet"
require "async/matrix"
require "json"
require "console"

module Async
  module Matrix
    # Async HTTP client for binary Matrix media operations.
    #
    # Handles raw byte uploads and downloads against the Matrix content
    # repository. Unlike the JSON-only Client, this never wraps request
    # bodies in JSON.generate and can return raw binary response bodies.
    #
    # Not intended to be used directly — the Chain dispatches here
    # automatically when the request path matches a BINARY_ROUTES entry.
    #
    #   media_client = Async::Matrix::MediaClient.new(config)
    #   media_client.upload("POST", path, bytes, "image/png")
    #   bytes = media_client.download(path)
    #
    class MediaClient
      # Upload JSON responses are small; error bodies are even smaller.
      UPLOAD_RESPONSE_SIZE_LIMIT = 1 * 1024 * 1024   # 1 MiB
      ERROR_RESPONSE_SIZE_LIMIT  = 512 * 1024          # 512 KiB

      def initialize(config)
        @config = config
        @base   = config.homeserver.address
        @auth_headers = [
          ["authorization", "Bearer #{config.appservice.as_token}"],
          ["user-agent",    "AsyncMatrix/#{Async::Matrix::VERSION}"]
        ]
      end

      # Upload raw bytes to the content repository.
      #
      # @param method [String] HTTP method ("POST" or "PUT")
      # @param path [String] URL path (already URL-encoded)
      # @param body [String] raw bytes to upload
      # @param content_type [String] MIME type of the body
      # @return [Hash] parsed JSON response (e.g. {"content_uri" => "mxc://..."})
      def upload(method, path, body, content_type = "application/octet-stream")
        url = "#{@base}#{path}"
        headers = @auth_headers + [["content-type", content_type]]

        Console.debug(self) { "UPLOAD #{method} #{path} (#{content_type}, #{body.bytesize} bytes)" }

        response = internet.call(method, url, headers, body)
        status   = response.status

        unless (200..299).cover?(status)
          payload = read_limited(response, ERROR_RESPONSE_SIZE_LIMIT)
          parsed = ApplicationService::ErrorResponse.new(
            begin; JSON.parse(payload); rescue; {} end
          )
          Console.error(self) { "Matrix media upload #{status}: #{parsed.errcode} — #{parsed.error}" }
          raise HomeserverError.new(
            parsed.errcode || "UNKNOWN",
            parsed.error || payload.to_s[0..200],
            status: status
          )
        end

        payload = read_limited(response, UPLOAD_RESPONSE_SIZE_LIMIT)
        payload && !payload.empty? ? JSON.parse(payload) : {}
      end

      # Download from the content repository.
      #
      # Returns the raw HTTP response object so the caller has access to
      # both the body and response metadata:
      #
      #   response = media_client.download(path)
      #   response.read                          # raw bytes (String, Encoding::BINARY)
      #   response.headers["content-type"]       # "image/png"
      #   response.headers["content-disposition"] # "inline; filename=\"photo.jpg\""
      #   response.body.each { |chunk| ... }     # streaming
      #
      # @param path [String] URL path (already URL-encoded, may include query string)
      # @return [Protocol::HTTP::Response] the HTTP response
      def download(path)
        url = "#{@base}#{path}"

        Console.debug(self) { "DOWNLOAD #{path}" }

        response = internet.call("GET", url, @auth_headers, nil)
        status   = response.status

        unless (200..299).cover?(status)
          payload = response.read
          parsed = ApplicationService::ErrorResponse.new(
            begin; JSON.parse(payload); rescue; {} end
          )
          Console.error(self) { "Matrix media download #{status}: #{parsed.errcode} — #{parsed.error}" }
          raise HomeserverError.new(
            parsed.errcode || "UNKNOWN",
            parsed.error || payload.to_s[0..200],
            status: status
          )
        end

        response
      end

      def close
        @internet&.close
        @internet = nil
      end

      private

      def internet
        @internet ||= Async::HTTP::Internet.new
      end

      # Read response body with a size limit. Raises ResponseTooLargeError
      # if the body exceeds the limit.
      def read_limited(response, limit)
        body = response.body
        return nil unless body

        if body.respond_to?(:length) && body.length && body.length > limit
          body.close
          raise ResponseTooLargeError.new(
            "M_TOO_LARGE",
            "Response Content-Length #{body.length} bytes exceeds limit of #{limit} bytes"
          )
        end

        buffer = String.new(encoding: Encoding::BINARY)
        body.each do |chunk|
          buffer << chunk
          if buffer.bytesize > limit
            body.close
            raise ResponseTooLargeError.new(
              "M_TOO_LARGE",
              "Response body exceeds limit of #{limit} bytes"
            )
          end
        end
        buffer.empty? ? nil : buffer
      end
    end
  end
end

test do
  describe "Async::Matrix::MediaClient" do
    def make_config
      Async::Matrix::ApplicationService::Config.new({
        "homeserver" => { "address" => "http://localhost:8008", "domain" => "localhost" },
        "appservice" => { "as_token" => "test_token", "hs_token" => "hs_secret", "bot" => { "username" => "bot" } }
      })
    end

    it "responds to upload and download" do
      client = Async::Matrix::MediaClient.new(make_config)
      client.should.respond_to :upload
      client.should.respond_to :download
    end

    it "can be closed without error" do
      client = Async::Matrix::MediaClient.new(make_config)
      lambda { client.close }.should.not.raise
    end
  end
end
