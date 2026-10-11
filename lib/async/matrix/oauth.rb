# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "base64"
require "digest"
require "openssl"
require "securerandom"

require "async/rest/resource"
require "async/rest/representation"

require "protocol/url/encoding"

require_relative "error"
require_relative "redacted"
require_relative "oauth/error"
require_relative "wrapper/client_registration"
require_relative "wrapper/token"

module Async
  module Matrix
    # The OAuth 2.0 API a homeserver delegates to.
    module OAuth
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
      class Tokens < Async::REST::Representation[Wrapper::Token]
        include Redacted

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

      # The empty answer a revocation gives.
      class Revoked < Async::REST::Representation[Wrapper::Token]
      end

      # The client this application registered as.
      class Registration < Async::REST::Representation[Wrapper::ClientRegistration]
        include Redacted

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

        # Begin an authorization, which the caller completes when the redirect returns.
        #
        # @parameter client_id [String] the registered client.
        # @parameter redirect_uri [String] where the code is returned to.
        # @parameter scope [String] what is being asked for.
        # @returns [Authorization] the authorization in progress.
        def authorize(client_id:, redirect_uri:, device_id: self.class.device_id, scope: nil, client_secret: nil)
          verifier = Verifier.generate
          state = self.class.state
          scope = scope || self.class.scope(device_id)

          url = self.authorization_url(
            client_id: client_id,
            redirect_uri: redirect_uri,
            verifier: verifier,
            scope: scope,
            state: state,
          )

          Authorization.new(self.endpoint(@metadata.token_endpoint),
            url: url,
            client_id: client_id,
            client_secret: client_secret,
            redirect_uri: redirect_uri,
            state: state,
            verifier: verifier,
            device_id: device_id,
            issuer: @metadata.issuer,
          )
        end

        # Withdraw a token, which is how an OAuth session is ended.
        #
        # @parameter token [String] the access or refresh token to withdraw.
        # @parameter client_id [String] the registered client.
        # @parameter token_type_hint [String | nil] `access_token` or `refresh_token`, if known.
        # @parameter client_secret [String | nil] the secret, for a client which was issued one.
        # @returns [Revoked] the empty answer.
        # @raises [Error] if the server has no revocation endpoint.
        def revoke(token, client_id:, token_type_hint: nil, client_secret: nil)
          endpoint = @metadata.revocation_endpoint

          unless endpoint
            raise Error.new(0, "invalid_request", "The authorization server published no revocation endpoint!")
          end

          payload = {token: token, client_id: client_id, token_type_hint: token_type_hint, client_secret: client_secret}

          Revoked.post(self.endpoint(endpoint), payload.compact)
        end

        # Redeem an authorization code for tokens.
        #
        # @parameter code [String] the code the redirect carried.
        # @parameter client_id [String] the registered client.
        # @parameter redirect_uri [String] the same URI the code was asked for with.
        # @parameter verifier [Verifier] the proof key the challenge was derived from.
        # @returns [Tokens] the tokens issued.
        def exchange(code, client_id:, redirect_uri:, verifier:, client_secret: nil)
          payload = {
            grant_type: "authorization_code",
            code: code,
            redirect_uri: redirect_uri,
            client_id: client_id,
            code_verifier: verifier.verifier,
            client_secret: client_secret,
          }

          Tokens.post(self.endpoint(@metadata.token_endpoint), payload.compact)
        end

        # Exchange a refresh token for a new access token.
        #
        # @parameter refresh_token [String] the refresh token to exchange.
        # @parameter client_id [String] the registered client.
        # @returns [Tokens] the tokens issued.
        def refresh(refresh_token, client_id:, client_secret: nil)
          payload = {
            grant_type: "refresh_token",
            refresh_token: refresh_token,
            client_id: client_id,
            client_secret: client_secret,
          }

          Tokens.post(self.endpoint(@metadata.token_endpoint), payload.compact)
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

      # An authorization in progress, which the caller holds until the redirect returns.
      #
      # The authorization endpoint is not a resource this library requests: its URL goes to the user's browser.
      class Authorization
        # @parameter resource [Async::REST::Resource] the token endpoint the code is redeemed at.
        # @parameter url [String] where to send the user to authorize.
        # @parameter client_id [String] the registered client.
        # @parameter redirect_uri [String] where the code is returned to.
        # @parameter state [String] the opaque value the redirect must carry back.
        # @parameter verifier [Verifier] the proof key the challenge was derived from.
        # @parameter device_id [String | nil] the device the scope asked the server to create.
        # @parameter issuer [String | nil] the authorization server, which the redirect may name back.
        # @parameter client_secret [String | nil] the secret, for a client which was issued one.
        def initialize(resource, url:, client_id:, redirect_uri:, state:, verifier:, device_id: nil, issuer: nil, client_secret: nil)
          @resource = resource
          @url = url
          @client_id = client_id
          @client_secret = client_secret
          @redirect_uri = redirect_uri
          @state = state
          @verifier = verifier
          @device_id = device_id
          @issuer = issuer
        end

        # @attribute [String] where to send the user to authorize.
        attr :url

        # @attribute [String] the opaque value the redirect must carry back.
        attr :state

        # @attribute [String | nil] the device the scope asked the server to create.
        attr :device_id

        # @attribute [String | nil] the authorization server the code must have come from.
        attr :issuer

        # Redeem the code the redirect carried.
        #
        # @parameter code [String] the authorization code.
        # @parameter state [String] the state the redirect carried.
        # @parameter iss [String | nil] the issuer the redirect named, which RFC 9207 asks us to check.
        # @returns [Tokens] the tokens issued.
        # @raises [Error] if the state or the issuer does not match the authorization request.
        def exchange(code, state:, iss: nil)
          unless ::OpenSSL.secure_compare(state, @state)
            raise Error.new(0, "invalid_grant", "The redirect state does not match the authorization request!")
          end

          # A redirect which names a different authorization server is one answering for somebody else:
          if iss and @issuer and !::OpenSSL.secure_compare(iss, @issuer)
            raise Error.new(0, "invalid_grant", "The redirect names #{iss} rather than #{@issuer}!")
          end

          payload = {
            grant_type: "authorization_code",
            code: code,
            redirect_uri: @redirect_uri,
            client_id: @client_id,
            code_verifier: @verifier.verifier,
            client_secret: @client_secret,
          }

          Tokens.post(@resource, payload.compact)
        end

        # Withdraw a token this authorization issued.
        #
        # @parameter token [String] the access or refresh token to withdraw.
        # @parameter token_type_hint [String | nil] `access_token` or `refresh_token`, if known.
        # @returns [Revoked] the empty answer.
        def revoke(token, token_type_hint: nil)
          payload = {token: token, client_id: @client_id, token_type_hint: token_type_hint, client_secret: @client_secret}

          Revoked.post(@resource, payload.compact)
        end

        def inspect
          "\#<#{self.class} #{@client_id}>"
        end
      end

      # Renews an access token at the authorization server.
      #
      # {Credentials} asks with the refresh token alone, where the authorization server also wants to know which client is asking.
      class Issuer
        # @parameter server [AuthorizationServer] the server which issues the tokens.
        # @parameter client_id [String] the registered client.
        # @parameter client_secret [String | nil] the secret, for a client which was issued one.
        def initialize(server, client_id, client_secret = nil)
          @server = server
          @client_id = client_id
          @client_secret = client_secret
        end

        # @parameter refresh_token [String] the refresh token to exchange.
        # @returns [Tokens] the tokens issued.
        def refresh(refresh_token)
          @server.refresh(refresh_token, client_id: @client_id, client_secret: @client_secret)
        end

        # Withdraw a token, which is how an OAuth session is ended.
        #
        # @parameter token [String] the token to withdraw.
        # @parameter token_type_hint [String | nil] `access_token` or `refresh_token`, if known.
        # @returns [Revoked] the empty answer.
        def revoke(token, token_type_hint: nil)
          @server.revoke(token, client_id: @client_id, token_type_hint: token_type_hint, client_secret: @client_secret)
        end

        # Close the authorization server, which is a connection to another host.
        #
        # @returns [Nil] nothing.
        def close
          @server.close
        end

        def inspect
          "\#<#{self.class} #{@client_id}>"
        end
      end
    end
  end
end
