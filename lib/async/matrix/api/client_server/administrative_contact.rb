# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/administrative_contact"

module Async
  module Matrix
    module ClientServer
      # A session the identity server opened to validate an address.
      #
      # Registration, a password reset and adding contact to an account all open one, so all three read it.
      class ThreePidValidation < Representation
        include Versioned

        # @returns [String | nil] the session to quote once the address has been validated.
        def sid
          self.value[:sid]
        end

        # @returns [String | nil] where to send the token, where the homeserver will not send it.
        def submit_url
          self.value[:submit_url]
        end
      end

      # What became of an identity server binding.
      #
      # Unbinding is the identity server's to do, so the homeserver reports what it managed.
      class UnbindResult < Representation
        include Versioned

        # @returns [String] `success` or `no-support`.
        def id_server_unbind_result
          self.value[:id_server_unbind_result]
        end

        # @returns [Boolean] whether the identity server unbound the address.
        def unbound?
          self.id_server_unbind_result == "success"
        end
      end

      # One address on a user's account.
      class ThreePid
        # @parameter value [Hash] the identifier as the homeserver sent it.
        def initialize(value)
          @value = value
        end

        # @returns [String] `email` or `msisdn`.
        def medium
          @value[:medium]
        end

        # @returns [String] the address itself.
        def address
          @value[:address]
        end

        # @returns [Integer] when the identity server validated it, in milliseconds since the epoch.
        def validated_at
          @value[:validated_at]
        end

        # @returns [Integer] when the homeserver attached it to the account.
        def added_at
          @value[:added_at]
        end
      end

      # The addresses on a user's account.
      class ThreePids < Representation
        include Versioned

        # @returns [Array(ThreePid)] the addresses.
        def threepids
          (self.value[:threepids] || []).map{|entry| ThreePid.new(entry)}
        end

        # @returns [Boolean] whether the account has none.
        def empty?
          self.threepids.empty?
        end
      end

      # The third party identifiers bound to an account.
      class AdministrativeContact
        include Versioned

        # @returns [String] the path of the addresses on an account.
        def self.path
          "#{V3}/account/3pid"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [AdministrativeContact] the identifiers.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # The addresses on this account.
        #
        # @returns [ThreePids] the addresses.
        def get_account_3pids
          api::ThreePids.get(@resource.with(path: self.class.path))
        end

        # Attach an address the identity server validated, the way v1.1 asked for.
        #
        # @parameter three_pid_creds [Hash] the identity server, the session and the secret.
        # @returns [ThreePidValidation] where to submit the token, where there is anywhere.
        def post_3pids(three_pid_creds)
          api::ThreePidValidation.post(@resource.with(path: self.class.path), {three_pid_creds: three_pid_creds})
        end

        # Attach an address this homeserver validated.
        #
        # @parameter client_secret [String] the secret the validation was asked for with.
        # @parameter sid [String] the validation session.
        # @parameter auth [Hash | nil] the user interactive authentication, where one is owed.
        # @returns [Representation] the empty response.
        def add_3pid(client_secret, sid, auth: nil)
          payload = {client_secret: client_secret, sid: sid, auth: auth}.compact

          api::Representation.post(@resource.with(path: "#{self.class.path}/add"), payload)
        end

        # Bind an address on the account to an identity server, so that others can find the user by it.
        #
        # @parameter client_secret [String] the secret the validation was asked for with.
        # @parameter id_server [String] the identity server which validated it.
        # @parameter id_access_token [String] the token for that identity server.
        # @parameter sid [String] the validation session.
        # @returns [Representation] the empty response.
        def bind_3pid(client_secret, id_server, id_access_token, sid)
          payload = {client_secret: client_secret, id_server: id_server, id_access_token: id_access_token, sid: sid}

          api::Representation.post(@resource.with(path: "#{self.class.path}/bind"), payload)
        end

        # Unbind an address from an identity server, leaving it on the account.
        #
        # @parameter medium [String] `email` or `msisdn`.
        # @parameter address [String] the address to unbind.
        # @parameter id_server [String | nil] the identity server to unbind from, or the one it was bound through.
        # @returns [UnbindResult] what the identity server did.
        def unbind_3pid_from_account(medium, address, id_server: nil)
          payload = {medium: medium, address: address, id_server: id_server}.compact

          api::UnbindResult.post(@resource.with(path: "#{self.class.path}/unbind"), payload)
        end

        # Remove an address from the account altogether.
        #
        # @parameter medium [String] `email` or `msisdn`.
        # @parameter address [String] the address to remove.
        # @parameter id_server [String | nil] the identity server to unbind from as well.
        # @returns [UnbindResult] what the identity server did.
        def delete_3pid_from_account(medium, address, id_server: nil)
          payload = {medium: medium, address: address, id_server: id_server}.compact

          api::UnbindResult.post(@resource.with(path: "#{self.class.path}/delete"), payload)
        end

        # Ask for a token to validate an email address with, so that it can be added.
        #
        # @parameter client_secret [String] a secret of the client's own, quoted back when the token is used.
        # @parameter email [String] the address to validate.
        # @parameter send_attempt [Integer] the attempt, which the homeserver sends again only when it rises.
        # @parameter options [Hash] the rest the specification allows, e.g. `next_link:`.
        # @returns [ThreePidValidation] the session the validation runs in.
        def request_token_to_3pid_email(client_secret, email, send_attempt: 1, **options)
          payload = {client_secret: client_secret, email: email, send_attempt: send_attempt, **options}

          api::ThreePidValidation.post(@resource.with(path: "#{self.class.path}/email/requestToken"), payload)
        end

        # Ask for a token to validate a phone number with, so that it can be added.
        #
        # @parameter client_secret [String] a secret of the client's own, quoted back when the token is used.
        # @parameter country [String] the two letter country code the number belongs to.
        # @parameter phone_number [String] the number to validate, as it is dialled in that country.
        # @parameter send_attempt [Integer] the attempt, which the homeserver sends again only when it rises.
        # @parameter options [Hash] the rest the specification allows, e.g. `next_link:`.
        # @returns [ThreePidValidation] the session the validation runs in.
        def request_token_to_3pid_msisdn(client_secret, country, phone_number, send_attempt: 1, **options)
          payload = {client_secret: client_secret, country: country, phone_number: phone_number, send_attempt: send_attempt, **options}

          api::ThreePidValidation.post(@resource.with(path: "#{self.class.path}/msisdn/requestToken"), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
