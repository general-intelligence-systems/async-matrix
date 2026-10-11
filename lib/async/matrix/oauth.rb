# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "base64"
require "digest"
require "securerandom"

require "async/rest/resource"
require "async/rest/representation"
require "async/rest/wrapper/form"
require "async/rest/wrapper/json"

require "protocol/url/encoding"

require_relative "error"

module Async
  module Matrix
    # The OAuth 2.0 API a homeserver delegates to.
    module OAuth
      # The error the authorization server reported.
      #
      # @parameter response [Protocol::HTTP::Response] the refusal.
      # @returns [Tuple(String, String | nil)] the error code and its description.
      def self.error_for(response)
        payload = response.read

        if payload.is_a?(Hash)
          [payload[:error] || "invalid_request", payload[:error_description]]
        else
          ["invalid_request", payload&.to_s]
        end
      rescue => error
        ["invalid_request", error.message]
      end

      # Raised when the authorization server refuses a request.
      #
      # A {RequestError}, so a caller which handles one refusal handles both.
      class Error < Matrix::RequestError
        # @returns [Boolean] whether the grant was rejected, so the caller must authorize again.
        def invalid_grant?
          self.errcode == "invalid_grant"
        end
      end

      # The form wrapper, corrected for the authorization server's error shape.
      #
      # A token request is form encoded and answered with JSON, which is what the token endpoint asks for.
      class Wrapper < Async::REST::Wrapper::Form
        # @parameter request [Protocol::HTTP::Request] the request that was made.
        # @parameter response [Protocol::HTTP::Response] the response that was received.
        # @returns [Protocol::HTTP::Response] the response.
        # @raises [Error] if the authorization server refused.
        def process_response(request, response)
          super

          unless response.success?
            error, description = OAuth.error_for(response)

            raise Error.new(response.status, error, description)
          end

          response
        end

        # Which parser to use, if the response says what it is.
        #
        # A response with no content type is left alone rather than raising.
        #
        # @parameter response [Protocol::HTTP::Response] the response to parse.
        # @returns [Class | nil] the parser.
        def parser_for(response)
          if response.headers["content-type"]
            super
          end
        end
      end

      # The JSON wrapper, for the registration endpoint, which takes JSON rather than a form.
      class JSONWrapper < Async::REST::Wrapper::JSON
        # @parameter request [Protocol::HTTP::Request] the request that was made.
        # @parameter response [Protocol::HTTP::Response] the response that was received.
        # @returns [Protocol::HTTP::Response] the response.
        # @raises [Error] if the authorization server refused.
        def process_response(request, response)
          super

          unless response.success?
            error, description = OAuth.error_for(response)

            raise Error.new(response.status, error, description)
          end

          response
        end
      end

      # A proof key, which ties an authorization code to the client that asked for it.
      #
      # A public client has no secret, so this is what guards the code.
      class Verifier
        # The challenge method this derives, which every authorization server supporting PKCE accepts.
        METHOD = "S256"

        # How many random bytes the verifier is built from. RFC 7636 wants between 43 and 128 characters, which this sits inside.
        ENTROPY = 48

        # @returns [Verifier] a new verifier, from fresh randomness.
        def self.generate
          self.new(SecureRandom.urlsafe_base64(ENTROPY))
        end

        # @parameter verifier [String] the secret the challenge is derived from.
        def initialize(verifier)
          @verifier = verifier
        end

        # @attribute [String] the secret, which is sent only when the code is redeemed.
        attr :verifier

        # The challenge to send with the authorization request.
        #
        # @returns [String] the URL safe, unpadded SHA-256 of the verifier.
        def challenge
          Base64.urlsafe_encode64(Digest::SHA256.digest(@verifier), padding: false)
        end

        # @returns [String] the method the challenge was derived with.
        def method
          METHOD
        end

        def inspect
          "\#<#{self.class} #{METHOD}>"
        end
      end

      # The tokens the authorization server issued.
      class Tokens < Async::REST::Representation[Wrapper]
        # @returns [String] the access token to authenticate with.
        def access_token
          self.value[:access_token]
        end

        # @returns [String | nil] the token which buys the next access token.
        def refresh_token
          self.value[:refresh_token]
        end

        # @returns [String | nil] how the access token is to be presented, e.g. `Bearer`.
        def token_type
          self.value[:token_type]
        end

        # @returns [Integer | nil] how long the access token lasts, in seconds.
        def expires_in
          self.value[:expires_in]
        end

        # How long the access token lasts in milliseconds, which is what Matrix reports and what {Credentials} expects.
        #
        # @returns [Integer | nil] the lifetime, in milliseconds.
        def expires_in_ms
          if expires_in = self.expires_in
            expires_in * 1000
          end
        end
      end

      # The client this application registered as.
      class Registration < Async::REST::Representation[JSONWrapper]
        # @returns [String] the identifier the authorization server assigned.
        def client_id
          self.value[:client_id]
        end

        # @returns [String | nil] the secret, which a public client is not issued.
        def client_secret
          self.value[:client_secret]
        end
      end

      # The authorization server a homeserver delegates authentication to.
      #
      # Its endpoints are named by the metadata rather than fixed, so this is built from what the homeserver published.
      class AuthorizationServer
        # The scope which asks for access to the Matrix API, as the specification defines it.
        API_SCOPE = "urn:matrix:org.matrix.msc2967.client:api:*"

        # The scope which asks for a device to be created, whose identifier is appended.
        DEVICE_SCOPE = "urn:matrix:org.matrix.msc2967.client:device"

        # @parameter metadata [ClientServer::AuthMetadata] what the homeserver published.
        # @returns [AuthorizationServer] the server, which the caller closes.
        def self.for(metadata)
          self.new(Async::REST::Resource.open(metadata.issuer), metadata)
        end

        # @parameter resource [Async::REST::Resource] the resource rooted at the issuer.
        # @parameter metadata [ClientServer::AuthMetadata] what the homeserver published.
        def initialize(resource, metadata)
          @resource = resource
          @metadata = metadata
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # @attribute [ClientServer::AuthMetadata] the metadata which named the endpoints.
        attr :metadata

        # The scopes which ask for a Matrix session on a new device.
        #
        # @parameter device_id [String] the device to create.
        # @returns [String] the scope parameter.
        def self.scope(device_id)
          "#{API_SCOPE} #{DEVICE_SCOPE}:#{device_id}"
        end

        # @returns [String] a device identifier, which the scope asks for.
        def self.device_id
          SecureRandom.urlsafe_base64(16)
        end

        # @returns [String] an opaque value, returned with the authorization code.
        def self.state
          SecureRandom.urlsafe_base64(16)
        end

        # Register this application, which a public client must do before it can authorize.
        #
        # @parameter client_metadata [Hash] the metadata RFC 7591 describes.
        # @returns [Registration] the client this application is now known as.
        def register(**client_metadata)
          Registration.post(self.endpoint(@metadata.registration_endpoint), client_metadata)
        end

        # Where to send the user so that they may authorize this client.
        #
        # @parameter client_id [String] the registered client.
        # @parameter redirect_uri [String] where the authorization code is returned to.
        # @parameter verifier [Verifier] the proof key the code will be redeemed with.
        # @parameter scope [String] what is being asked for.
        # @parameter state [String] an opaque value returned with the code.
        # @returns [String] the URL to open.
        def authorization_url(client_id:, redirect_uri:, verifier:, scope:, state: self.class.state)
          parameters = {
            response_type: "code",
            client_id: client_id,
            redirect_uri: redirect_uri,
            scope: scope,
            state: state,
            code_challenge: verifier.challenge,
            code_challenge_method: verifier.method,
          }

          "#{@metadata.authorization_endpoint}?#{::Protocol::URL::Encoding.encode(parameters)}"
        end

        # Redeem an authorization code for tokens.
        #
        # @parameter code [String] the code the redirect carried.
        # @parameter client_id [String] the registered client.
        # @parameter redirect_uri [String] the same URI the code was asked for with.
        # @parameter verifier [Verifier] the proof key the challenge was derived from.
        # @returns [Tokens] the tokens issued.
        def exchange(code, client_id:, redirect_uri:, verifier:)
          Tokens.post(self.endpoint(@metadata.token_endpoint), {
            grant_type: "authorization_code",
            code: code,
            redirect_uri: redirect_uri,
            client_id: client_id,
            code_verifier: verifier.verifier,
          })
        end

        # Exchange a refresh token for a new access token.
        #
        # @parameter refresh_token [String] the refresh token to exchange.
        # @parameter client_id [String] the registered client.
        # @returns [Tokens] the tokens issued.
        def refresh(refresh_token, client_id:)
          Tokens.post(self.endpoint(@metadata.token_endpoint), {
            grant_type: "refresh_token",
            refresh_token: refresh_token,
            client_id: client_id,
          })
        end

        def close
          @resource.close
        end

        def inspect
          "\#<#{self.class} #{@metadata.issuer}>"
        end

        # The resource of one endpoint the metadata named.
        #
        # @parameter url [String] the endpoint, which must share the issuer's origin.
        # @returns [Async::REST::Resource] the resource.
        # @raises [Error] if the endpoint is on another host.
        private def endpoint(url)
          endpoint = Async::HTTP::Endpoint.parse(url)
          issuer = Async::HTTP::Endpoint.parse(@metadata.issuer)

          unless endpoint.authority == issuer.authority and endpoint.scheme == issuer.scheme
            raise Error.new(0, "invalid_request", "The endpoint #{url} is not on the issuer #{@metadata.issuer}!")
          end

          @resource.with(path: endpoint.path)
        end
      end

      # Renews an access token at the authorization server.
      #
      # {Credentials} asks with the refresh token alone, where the authorization server also wants to know which client is asking.
      class Issuer
        # @parameter server [AuthorizationServer] the server which issues the tokens.
        # @parameter client_id [String] the registered client.
        def initialize(server, client_id)
          @server = server
          @client_id = client_id
        end

        # @parameter refresh_token [String] the refresh token to exchange.
        # @returns [Tokens] the tokens issued.
        def refresh(refresh_token)
          @server.refresh(refresh_token, client_id: @client_id)
        end

        def inspect
          "\#<#{self.class} #{@client_id}>"
        end
      end
    end
  end
end
