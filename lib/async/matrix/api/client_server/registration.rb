# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../removals"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/registration"
require_relative "administrative_contact"
require_relative "session"

module Async
  module Matrix
    module ClientServer
      # Whether a username can still be registered.
      class UsernameAvailability < Representation
        include Versioned

        # @returns [Boolean] whether it is free, which the homeserver only promises for the moment it answered.
        def available?
          self.value[:available]
        end
      end

      # Registering an account.
      #
      # v1.15 moved the password and deactivation operations out, so each is reached through its own class from then on.
      class Registration
        include Versioned

        # @returns [String] the path registration is asked for at.
        def self.path
          "#{V3}/register"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Registration] the registration.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Register an account.
        #
        # The homeserver answers with the fields a login does, unless asked not to log in.
        #
        # @parameter username [String | nil] the localpart wanted, or nil to be given one.
        # @parameter password [String | nil] the password to set.
        # @parameter kind [String] `user` or `guest`.
        # @parameter payload [Hash] the rest the specification allows, e.g. `auth:`, `inhibit_login:`.
        # @returns [Login] the account, and the session it was registered with.
        def register(username: nil, password: nil, kind: "user", **payload)
          body = {username: username, password: password, **payload}.compact

          api::Login.post(@resource.with(path: self.class.path, parameters: {kind: kind}), body)
        end

        # Whether a username is free to register.
        #
        # @parameter username [String] the localpart to ask about.
        # @returns [UsernameAvailability] whether it is free.
        def check_username_availability(username)
          api::UsernameAvailability.get(@resource.with(path: "#{self.class.path}/available", parameters: {username: username}))
        end

        # Ask for a token to validate an email address with, so that it can be registered against.
        #
        # @parameter client_secret [String] a secret of the client's own, quoted back when the token is used.
        # @parameter email [String] the address to validate.
        # @parameter send_attempt [Integer] the attempt, which the homeserver sends again only when it rises.
        # @parameter options [Hash] the rest the specification allows, e.g. `next_link:`.
        # @returns [ThreePidValidation] the session the validation runs in.
        def request_token_to_register_email(client_secret, email, send_attempt: 1, **options)
          payload = {client_secret: client_secret, email: email, send_attempt: send_attempt, **options}

          api::ThreePidValidation.post(@resource.with(path: "#{self.class.path}/email/requestToken"), payload)
        end

        # Ask for a token to validate a phone number with, so that it can be registered against.
        #
        # @parameter client_secret [String] a secret of the client's own, quoted back when the token is used.
        # @parameter country [String] the two letter country code the number belongs to.
        # @parameter phone_number [String] the number to validate, as it is dialled in that country.
        # @parameter send_attempt [Integer] the attempt, which the homeserver sends again only when it rises.
        # @parameter options [Hash] the rest the specification allows, e.g. `next_link:`.
        # @returns [ThreePidValidation] the session the validation runs in.
        def request_token_to_register_msisdn(client_secret, country, phone_number, send_attempt: 1, **options)
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
