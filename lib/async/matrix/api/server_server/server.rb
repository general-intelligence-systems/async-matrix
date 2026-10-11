# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/rest/resource"

require_relative "../../version"
require_relative "../../versions"
require_relative "../../versioned"
require_relative "../../paths"
require_relative "../../representation"
require_relative "../../server_key"
require_relative "../../middleware/rate_limited"
require_relative "../../middleware/signed"
require_relative "backfill"
require_relative "content_repository"
require_relative "event_auth"
require_relative "events"
require_relative "invites_v1"
require_relative "invites_v2"
require_relative "joins_v1"
require_relative "joins_v2"
require_relative "keys_query"
require_relative "keys_server"
require_relative "knocks"
require_relative "leaving_v1"
require_relative "leaving_v2"
require_relative "openid"
require_relative "public_rooms"
require_relative "query"
require_relative "room_policy"
require_relative "space_hierarchy"
require_relative "third_party_invite"
require_relative "transactions"
require_relative "user_devices"
require_relative "user_keys"
require_relative "version"
require_relative "wellknown"

module Async
  module Matrix
    # @namespace
    module ServerServer
      # Another homeserver, as this one reaches it.
      #
      # It is rooted at the server rather than a versioned base path, because the API is versioned per-endpoint.
      class Server < Async::REST::Resource
        include Versioned

        class << self
          # The server for a given specification version.
          #
          # @example
          #   Async::Matrix::ServerServer::Server["v1.19"].open(url)
          #
          # @parameter version [String | Symbol] e.g. `"v1.19"` or `"1.19"`.
          # @returns [Class(Server)] the server for that version.
          def [](version)
            Versions[version, self.namespace]::Server
          end
        end

        # The default server to connect to.
        ENDPOINT = Async::HTTP::Endpoint.parse("http://localhost:8008")

        # The user agent supplied with every request.
        USER_AGENT = "async-matrix/#{VERSION}"

        # Connect to the server, waiting out a rate limit on every request.
        #
        # @parameter endpoint [Async::HTTP::Endpoint] the server to connect to.
        # @returns [Tuple(Protocol::HTTP::Middleware, Protocol::URL::Reference)] the delegate and the reference.
        def self.connect(endpoint)
          delegate, reference = super

          [Middleware::RateLimited.new(delegate), reference]
        end

        # Every server carries the user agent, signed or not.
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

        # Derive a server which signs every request as the given server name.
        #
        # @parameter origin [String] the server name the requests are made by.
        # @parameter key [ServerKey] the key the origin signs with.
        # @parameter destination [String] the server name the requests are made to.
        # @returns [Server] a server which signs.
        def signed_as(origin, key, destination)
          self.class.new(Middleware::Signed.new(self.delegate, origin, key, destination), self.reference, self.headers)
        end

        # @returns [Backfill] the events before the ones we have.
        def backfill
          api::Backfill.for(self)
        end

        # @returns [ContentRepository] the files another server holds.
        def content_repository
          api::ContentRepository.for(self)
        end

        # @returns [EventAuth] the events which authorise an event.
        def event_auth
          api::EventAuth.for(self)
        end

        # @returns [Events] the events of a room, and the state around them.
        def events
          api::Events.for(self)
        end

        # @returns [InvitesV1] inviting a user, as the first version of the endpoint.
        def invites_v1
          api::InvitesV1.for(self)
        end

        # @returns [InvitesV2] inviting a user, which carries the room version.
        def invites_v2
          api::InvitesV2.for(self)
        end

        # @returns [JoinsV1] joining a room, as the first version of the endpoint.
        def joins_v1
          api::JoinsV1.for(self)
        end

        # @returns [JoinsV2] joining a room, which may leave out the members.
        def joins_v2
          api::JoinsV2.for(self)
        end

        # @returns [KeysQuery] the keys a notary server holds for another.
        def keys_query
          api::KeysQuery.for(self)
        end

        # @returns [KeysServer] the keys a server publishes for itself.
        def keys_server
          api::KeysServer.for(self)
        end

        # @returns [Knocks] knocking on a room.
        def knocks
          api::Knocks.for(self)
        end

        # @returns [LeavingV1] leaving a room, as the first version of the endpoint.
        def leaving_v1
          api::LeavingV1.for(self)
        end

        # @returns [LeavingV2] leaving a room.
        def leaving_v2
          api::LeavingV2.for(self)
        end

        # @returns [OpenID] who an OpenID token belongs to.
        def openid
          api::OpenID.for(self)
        end

        # @returns [PublicRooms] the rooms another server publishes.
        def public_rooms
          api::PublicRooms.for(self)
        end

        # @returns [Query] what another server will tell us about a user or an alias.
        def query
          api::Query.for(self)
        end

        # @returns [RoomPolicy] the policy server a room checks its events with.
        def room_policy
          api::RoomPolicy.for(self)
        end

        # @returns [SpaceHierarchy] the rooms a space holds.
        def space_hierarchy
          api::SpaceHierarchy.for(self)
        end

        # @returns [ThirdPartyInvite] inviting someone by an address rather than an ID.
        def third_party_invite
          api::ThirdPartyInvite.for(self)
        end

        # @returns [Transactions] the events and ephemeral data sent between servers.
        def transactions
          api::Transactions.for(self)
        end

        # @returns [UserDevices] the devices a user has logged in from.
        def user_devices
          api::UserDevices.for(self)
        end

        # @returns [UserKeys] the end to end encryption keys of a user.
        def user_keys
          api::UserKeys.for(self)
        end

        # @returns [ServerVersion] the software another server is running.
        def server_version
          api::ServerVersion.for(self)
        end

        # @returns [Wellknown] where a server should look for another.
        def wellknown
          api::Wellknown.for(self)
        end
      end
    end
  end
end
