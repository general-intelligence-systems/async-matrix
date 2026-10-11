# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/rest/resource"

require "protocol/url/encoding"

require_relative "../../version"
require_relative "../../versions"
require_relative "../../versioned"
require_relative "../../paths"
require_relative "../../representation"
require_relative "../../credentials"
require_relative "../../authenticated"
require_relative "../../oauth"
require_relative "../../abstract/api/client_server/client"
require_relative "session"
require_relative "key_backup"
require_relative "keys"
require_relative "to_device"
require_relative "cross_signing"
require_relative "device_management"
require_relative "rooms"
require_relative "sync"
require_relative "account_data"
require_relative "account_deactivation"
require_relative "admin"
require_relative "administrative_contact"
require_relative "appservice_ping"
require_relative "appservice_room_directory"
require_relative "authed_content_repo"
require_relative "banning"
require_relative "capabilities"
require_relative "content_repo"
require_relative "directory"
require_relative "event_context"
require_relative "filter"
require_relative "inviting"
require_relative "kicking"
require_relative "knocking"
require_relative "list_public_rooms"
require_relative "login_token"
require_relative "mutual_rooms"
require_relative "notifications"
require_relative "oauth_server_metadata"
require_relative "old_sync"
require_relative "openid"
require_relative "password_management"
require_relative "peeking_events"
require_relative "policy_server"
require_relative "presence"
require_relative "profile"
require_relative "pusher"
require_relative "pushrules"
require_relative "read_markers"
require_relative "receipts"
require_relative "redaction"
require_relative "refresh"
require_relative "oauth_server_metadata"
require_relative "registration"
require_relative "registration_tokens"
require_relative "relations"
require_relative "report_content"
require_relative "room_event_by_timestamp"
require_relative "room_initial_sync"
require_relative "room_summary"
require_relative "room_upgrades"
require_relative "search"
require_relative "space_hierarchy"
require_relative "sso_login_redirect"
require_relative "support"
require_relative "tags"
require_relative "third_party_lookup"
require_relative "third_party_membership"
require_relative "threads_list"
require_relative "typing"
require_relative "users"
require_relative "versions"
require_relative "voip"
require_relative "wellknown"

module Async
  module Matrix
    module ClientServer
      # A client for the Matrix client-server API.
      #
      # It is rooted at the homeserver rather than a versioned base path.
      class Client < Async::REST::Resource
        include Versioned

        class << self
          # The client for a given specification version.
          #
          # @example
          #   Async::Matrix::Client["v1.19"].open(url)
          #
          # @parameter version [String | Symbol] e.g. `"v1.19"` or `"1.19"`.
          # @returns [Class(Client)] the client for that version.
          def [](version)
            Versions[version, self.namespace]::Client
          end
        end

        # The default homeserver to connect to.
        ENDPOINT = Async::HTTP::Endpoint.parse("http://localhost:8008")

        # The user agent supplied with every request.
        USER_AGENT = "async-matrix/#{VERSION}"

        # Every client carries the user agent, authenticated or not.
        #
        # `Resource.open` cannot supply it, because it forwards `headers:` into a positional parameter. Both `open` and `with` build through here.
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

        # What the homeserver will let this user do.
        #
        # @returns [Capabilities] the capabilities.
        def get_capabilities
          api::Capabilities.get(self.with(path: "#{V3}/capabilities"))
        end

        # @returns [Representation] the specification versions supported by the homeserver.
        def versions
          api::Representation.get(self.with(path: "/_matrix/client/versions"))
        end

        # Derive a client which authenticates using the given access token.
        #
        # The token goes below the resource, not into its headers.
        #
        # @parameter access_token [String] the access token obtained from {#login}.
        # @returns [Client] an authenticated client.
        def authenticated(access_token)
          # Nothing to renew with: an access token can only be replaced from v1.3, whose layer passes the endpoint which does it.
          self.with_credentials(Credentials.new(nil, access_token: access_token))
        end

        # Derive a client which authenticates with the given credentials.
        #
        # @parameter credentials [Credentials] the access token, and whatever may replace it.
        # @returns [Client] an authenticated client.
        def with_credentials(credentials)
          self.class.new(Authenticated.new(self.delegate, credentials), self.reference, self.headers)
        end

        # Log in using a password.
        #
        # @parameter user [String] the localpart or fully qualified ID of the user.
        # @parameter password [String] the user's password.
        # @returns [Login] the login response, which carries the access token.
        def login(user, password, type: "m.login.password", **payload)
          payload[:type] = type
          payload[:identifier] = {type: "m.id.user", user: user}
          payload[:password] = password

          api::Login.post(self.with(path: "#{V3}/login"), payload)
        end

        # Log in using a password, and derive an authenticated client from the result.
        #
        # @parameter user [String] the localpart or fully qualified ID of the user.
        # @parameter password [String] the user's password.
        # @returns [Client] an authenticated client.
        def logged_in(user, password, **options)
          login = self.login(user, password, **options)

          # The login representation shares this client's connection, so it is not closed here: closing it would close the connection the derived client is about to use.
          self.authenticated(login.access_token)
        end

        # The ways this homeserver will let a user log in. No authentication is required.
        #
        # @returns [LoginFlows] the supported login flows.
        def get_login_flows
          api::LoginFlows.get(self.with(path: "#{V3}/login"))
        end

        # Invalidate this client's access token, so that the device is logged out.
        #
        # @returns [Representation] the empty response.
        def logout
          api::Representation.post(self.with(path: "#{V3}/logout"), {})
        end

        # Invalidate every access token for this user, logging out all of their devices.
        #
        # @returns [Representation] the empty response.
        def logout_all
          api::Representation.post(self.with(path: "#{V3}/logout/all"), {})
        end

        # @returns [Whoami] the identity associated with this client's access token.
        def get_token_owner
          api::Whoami.get(self.with(path: "#{V3}/account/whoami"))
        end

        # @returns [JoinedRooms] the rooms this user has joined.
        def get_joined_rooms
          api::JoinedRooms.new(self.with(path: "#{V3}/joined_rooms"))
        end

        # A room, by ID. No request is made.
        #
        # @parameter id [String] the room ID, e.g. `!abc:localhost`.
        # @returns [Room] the room.
        def room(id)
          api::Room.for(self, id)
        end

        # Create a room.
        #
        # @parameter payload [Hash] the room creation options, e.g. `name:`, `topic:`, `preset:`.
        # @returns [Room] the created room.
        def create_room(**payload)
          created = api::RoomReference.post(self.with(path: "#{V3}/createRoom"), payload)

          self.room(created.room_id)
        end

        # Join a room, by ID or alias.
        #
        # @parameter id_or_alias [String] the room ID or alias, e.g. `#general:localhost`.
        # @returns [Room] the joined room.
        def join_room(id_or_alias, **payload)
          path = "#{V3}/join/#{::Protocol::URL::Encoding.escape(id_or_alias)}"

          joined = api::RoomReference.post(self.with(path: path), payload)

          self.room(joined.room_id)
        end

        # @returns [Keys] the end to end encryption keys.
        def keys
          api::Keys.for(self)
        end

        # @returns [KeyBackup] the versions of this user's key backup.
        def key_backup
          api::KeyBackup.for(self)
        end

        # @returns [ToDevice] the sender of device addressed events.
        def to_device
          api::ToDevice.for(self)
        end

        # @returns [CrossSigning] the cross signing keys.
        def cross_signing
          api::CrossSigning.for(self)
        end

        # @returns [DeviceManagement] the devices this user has logged in from.
        def devices
          api::DeviceManagement.for(self)
        end

        # @returns [Typing] the typing state of a user in a room.
        def typing
          api::Typing.for(self)
        end

        # @returns [RoomEventByTimestamp] the lookup of the event nearest a time.
        def room_event_by_timestamp
          api::RoomEventByTimestamp.for(self)
        end

        # @returns [Profile] the display names, avatars and other profile fields.
        def profile
          api::Profile.for(self)
        end

        # Begin syncing.
        #
        # @parameter since [String | nil] the batch token to start from, or nil for the initial sync.
        # @parameter timeout [Integer] how long the server should wait, in milliseconds.
        # @returns [Sync] the first batch.
        def sync(since: nil, timeout: Sync::DEFAULT_TIMEOUT, **parameters)
          api::Sync.start(self, since: since, timeout: timeout, **parameters)
        end
      end
    end
  end
end
