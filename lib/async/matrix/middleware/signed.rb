# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "json"

require "protocol/http/body/buffered"
require "protocol/http/middleware"

require_relative "../server_key"

module Async
  module Matrix
    module Middleware
      # Signs every request with the server's own key.
      #
      # A server proves who it is by signing the request rather than by carrying a token.
      class Signed < ::Protocol::HTTP::Middleware
        # The authorization scheme a signature is carried under.
        SCHEME = "X-Matrix"

        # @parameter delegate [Protocol::HTTP::Middleware] what handles requests.
        # @parameter origin [String] the server name the requests are made by.
        # @parameter key [ServerKey] the key the origin signs with.
        # @parameter destination [String] the server name the requests are made to.
        def initialize(delegate, origin, key, destination)
          super(delegate)

          @origin = origin
          @key = key
          @destination = destination
        end

        # @attribute [String] the server name the requests are made by.
        attr :origin

        # @attribute [ServerKey] the key the origin signs with.
        attr :key

        # @attribute [String] the server name the requests are made to.
        attr :destination

        # Sign the request, and make it.
        #
        # @parameter request [Protocol::HTTP::Request] the request to make.
        # @returns [Protocol::HTTP::Response] the response.
        def call(request)
          # `Protocol::HTTP::Headers#[]=` replaces where `merge` adds, and a server rejects a request carrying two authorization headers:
          request.headers["authorization"] = self.authorization(request)

          super
        end

        def inspect
          "\#<#{self.class} #{@origin} -> #{@destination} as #{@key.id}>"
        end

        # The header which carries the signature, and what it was made over.
        #
        # @parameter request [Protocol::HTTP::Request] the request to sign.
        # @returns [String] the authorization header.
        private def authorization(request)
          signature = @key.sign(self.signable(request))

          "#{SCHEME} origin=#{self.quoted(@origin)},destination=#{self.quoted(@destination)},key=#{self.quoted(@key.id)},sig=#{self.quoted(signature)}"
        end

        # The object a signature is made over.
        #
        # The URI is the path as it is sent, and the content is the body as a document.
        #
        # @parameter request [Protocol::HTTP::Request] the request to sign.
        # @returns [Hash] the object to sign.
        private def signable(request)
          {
            method: request.method,
            uri: request.path,
            origin: @origin,
            destination: @destination,
          }.tap do |object|
            content = self.content(request)

            unless content.nil?
              object[:content] = content
            end
          end
        end

        # The body as a document, read back so that it can be signed and then sent.
        #
        # Reading consumes the body, so it is replaced with what was read.
        #
        # @parameter request [Protocol::HTTP::Request] the request whose body to read.
        # @returns [Hash | nil] the document, or nil where the request carries no body.
        private def content(request)
          body = request.body

          if body.nil?
            nil
          else
            bytes = body.join

            request.body = ::Protocol::HTTP::Body::Buffered.new([bytes])

            self.document(bytes)
          end
        end

        # @parameter bytes [String] the body which was read.
        # @returns [Hash | nil] the document it holds, or nil where it holds none.
        private def document(bytes)
          if bytes.nil? or bytes.empty?
            nil
          else
            ::JSON.parse(bytes)
          end
        end

        # @parameter value [String] the value to quote.
        # @returns [String] the value, as a quoted string.
        private def quoted(value)
          "\"#{value}\""
        end
      end
    end
  end
end
