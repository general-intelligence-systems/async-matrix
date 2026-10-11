# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/http/endpoint"
require "async/rest/resource"

require_relative "../../paths"
require_relative "../../version"
require_relative "../../versioned"
require_relative "../../versions"
require_relative "v2_associations"
require_relative "v2_auth"
require_relative "v2_email_associations"
require_relative "v2_invitation_signing"
require_relative "v2_lookup"
require_relative "v2_phone_associations"
require_relative "v2_ping"
require_relative "v2_pubkey"
require_relative "v2_store_invite"
require_relative "v2_terms"
require_relative "versions"

module Async
  module Matrix
    # The identity server API, which answers for addresses.
    module Identity
      # A client for the Matrix identity service API.
      #
      # An identity server holds which address belongs to which user, so that somebody with only an address can be invited.
      class Client < Async::REST::Resource
        include Versioned

        class << self
          # The client for a given specification version.
          #
          # @example
          #   Async::Matrix::Identity::Client["v1.19"].open(url)
          #
          # @parameter version [String | Symbol] e.g. `"v1.19"` or `"1.19"`.
          # @returns [Class(Client)] the client for that version.
          def [](version)
            Versions[version, self.namespace]::Client
          end
        end

        # The user agent supplied with every request.
        USER_AGENT = "async-matrix/#{VERSION}"

        # Every client carries the user agent, authenticated or not.
        #
        # @parameter delegate [Async::HTTP::Middleware] what handles requests.
        # @parameter reference [Protocol::URL::Reference] the base path and parameters.
        # @parameter headers [Protocol::HTTP::Headers] the headers every request carries.
        def initialize(delegate, reference = ::Protocol::URL::Reference.parse, headers = ::Protocol::HTTP::Headers.new)
          super(delegate, reference, headers)

          unless @headers["user-agent"]
            @headers = @headers.merge("user-agent" => USER_AGENT)
          end
        end

        # Derive a client which authenticates with the given token.
        #
        # The token is the one {V2Auth#register_account} issued, not the homeserver's.
        #
        # @parameter token [String] the token to carry.
        # @returns [Client] an authenticated client.
        def authenticated(token)
          self.with(headers: {"authorization" => "Bearer #{token}"})
        end

        # @returns [V2Ping] whether the server is there.
        def v2_ping
          api::V2Ping.for(self)
        end

        # @returns [SupportedVersions] the versions the server implements.
        def supported_versions
          api::SupportedVersions.for(self)
        end

        # @returns [V2Auth] the token this server is talked to with.
        def v2_auth
          api::V2Auth.for(self)
        end

        # @returns [V2Pubkey] the keys this server signs with.
        def v2_pubkey
          api::V2Pubkey.for(self)
        end

        # @returns [V2Terms] the policies this server asks a user to accept.
        def v2_terms
          api::V2Terms.for(self)
        end

        # @returns [V2Lookup] looking up the users behind addresses.
        def v2_lookup
          api::V2Lookup.for(self)
        end

        # @returns [V2Associations] the associations between an address and a user.
        def v2_associations
          api::V2Associations.for(self)
        end

        # @returns [V2EmailAssociations] validating an email address.
        def v2_email_associations
          api::V2EmailAssociations.for(self)
        end

        # @returns [V2PhoneAssociations] validating a phone number.
        def v2_phone_associations
          api::V2PhoneAssociations.for(self)
        end

        # @returns [V2StoreInvite] inviting someone who has no account yet.
        def v2_store_invite
          api::V2StoreInvite.for(self)
        end

        # @returns [V2InvitationSigning] signing an invitation which was sent to an address.
        def v2_invitation_signing
          api::V2InvitationSigning.for(self)
        end
      end
    end
  end
end
