# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/semaphore"

require_relative "error"

module Async
  module Matrix
    # The access token a client authenticates with, and the means to replace it.
    #
    # It lives below the resource because `#with` copies headers into every resource derived from one.
    class Credentials
      # How long before expiry a token is replaced. A sync long poll outlives a token with seconds left on it, so the margin is longer than the longest poll the token will be used for.
      MARGIN = 60.0

      # When an access token with the given lifetime expires.
      #
      # @parameter expires_in_ms [Integer | nil] the lifetime, in milliseconds.
      # @returns [Time | nil] when it expires, or nil if the homeserver did not say.
      def self.expires_at(expires_in_ms)
        if expires_in_ms
          Time.now + (expires_in_ms / 1000.0)
        end
      end

      # @parameter refresh [ClientServer::Refresh] the unauthenticated endpoint which issues tokens.
      # @parameter access_token [String] the token to authenticate with.
      # @parameter refresh_token [String | nil] the token which buys a new access token.
      # @parameter expires_in_ms [Integer | nil] how long the access token lasts.
      def initialize(refresh, access_token:, refresh_token: nil, expires_in_ms: nil)
        @refresh = refresh

        @access_token = access_token
        @refresh_token = refresh_token
        @expires_at = self.class.expires_at(expires_in_ms)

        # Bumped on every replacement, so that a rejected request can tell "my token is stale" from "somebody has already replaced it":
        @generation = 0

        # A replacement rotates the refresh token, so two at once would store one pair and discard the other:
        @semaphore = Async::Semaphore.new(1)

        # The refusal which ended this session, once one has. Remembered so that a burst of requests carrying a dead token asks the homeserver once rather than once each:
        @rejection = nil
      end

      # @attribute [String] the access token requests are authenticated with.
      attr :access_token

      # @attribute [String | nil] the token which buys the next access token.
      attr :refresh_token

      # @attribute [Time | nil] when the access token expires, if the homeserver said.
      attr :expires_at

      # @attribute [Integer] how many times the access token has been replaced.
      attr :generation

      # Whether a refusal is one the homeserver may recover from, leaving the session alone.
      #
      # @parameter error [RequestError] the refusal.
      # @returns [Boolean] whether the session may still be good.
      def self.transient?(error)
        # A server error is the homeserver having a bad moment, and a rate limit is it asking us to wait. Anything else is a verdict on the refresh token itself.
        error.status >= 500 or error.status == 429
      end

      # Whether there is both a refresh token and somewhere to spend it.
      #
      # @returns [Boolean] whether there is anything to replace the access token with.
      def renewable?
        !@refresh.nil? and !@refresh_token.nil?
      end

      # Whether the access token has expired, or is close enough that it should be replaced now.
      #
      # @parameter now [Time] the time to measure against.
      # @returns [Boolean] whether it needs replacing.
      def expiring?(now = Time.now)
        if @expires_at
          now >= (@expires_at - MARGIN)
        else
          false
        end
      end

      # The authorization header to send, replacing the access token first if it is about to expire.
      #
      # @returns [Tuple(String, Integer)] the header value, and the generation it came from.
      def authorization
        if self.renewable? and self.expiring?
          self.renew!
        end

        ["Bearer #{@access_token}", @generation]
      end

      # Replace the access token, unless it has already been replaced since the given generation.
      #
      # @parameter generation [Integer] the generation the caller's token came from.
      # @returns [Integer] the current generation.
      # @raises [AuthenticationError] if the homeserver would not issue a new token.
      def renew!(generation = @generation)
        @semaphore.acquire do
          if @generation > generation
            @generation
          elsif @rejection
            raise @rejection
          else
            self.replace!
          end
        end
      end

      # Adopt tokens obtained some other way.
      #
      # Every resource derived from the client shares these credentials, so the resource graph does not have to be rebuilt after logging in again.
      #
      # @parameter access_token [String] the token to authenticate with from now on.
      # @parameter refresh_token [String | nil] the token which buys the next access token.
      # @parameter expires_in_ms [Integer | nil] how long the access token lasts.
      # @returns [Integer] the new generation.
      def replace(access_token:, refresh_token: nil, expires_in_ms: nil)
        @semaphore.acquire do
          @access_token = access_token
          @refresh_token = refresh_token || @refresh_token
          @expires_at = self.class.expires_at(expires_in_ms)

          # The session is no longer known to be dead:
          @rejection = nil

          @generation += 1
        end
      end

      # Close whatever issues the tokens, which may hold a connection of its own.
      #
      # @returns [Nil] nothing.
      def close
        @refresh&.close
      end

      def inspect
        "\#<#{self.class} generation=#{@generation} renewable=#{self.renewable?}>"
      end

      # Exchange the refresh token for a new access token, and adopt whatever comes back.
      #
      # @returns [Integer] the new generation.
      # @raises [AuthenticationError] if the homeserver would not issue a new token.
      private def replace!
        begin
          refreshed = @refresh.refresh(@refresh_token)
        rescue RequestError => error
          if self.class.transient?(error)
            # The session may still be good, so the caller is told what went wrong rather than to log in again:
            raise
          else
            # Reported with the refusal's own status and code, so that a caller which already handles a rejected token handles this too. Logging out invalidates the refresh token along with the access token, which is exactly this path.
            @rejection = AuthenticationError.new(error.status, error.errcode, "The access token could not be replaced.")

            raise @rejection
          end
        end

        @access_token = refreshed.access_token

        # The homeserver may omit a new refresh token, in which case the existing one stands:
        @refresh_token = refreshed.refresh_token || @refresh_token

        @expires_at = self.class.expires_at(refreshed.expires_in_ms)
        @generation += 1

        @generation
      end
    end
  end
end
