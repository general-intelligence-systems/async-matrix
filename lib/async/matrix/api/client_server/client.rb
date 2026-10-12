# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/rest/resource"

require "protocol/url/encoding"

require_relative "../../version"
require_relative "../../versions"
require_relative "../../versioned"
require_relative "../../paths"
require_relative "../../representation"
require_relative "../../credentials"
require_relative "../../middleware/authenticated"
require_relative "../../middleware/rate_limited"
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

        # Connect to the homeserver, waiting out a rate limit on every request.
        #
        # An unauthenticated client is rate limited too, `/login` especially.
        #
        # @parameter endpoint [Async::HTTP::Endpoint] the homeserver to connect to.
        # @returns [Tuple(Protocol::HTTP::Middleware, Protocol::URL::Reference)] the delegate and the reference.
        def self.connect(endpoint)
          delegate, reference = super

          [Middleware::RateLimited.new(delegate), reference]
        end

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

        # The specification versions the homeserver implements.
        #
        # The short way to ask {SupportedVersions#get_versions}.
        #
        # @returns [ServerVersions] what it implements.
        def versions
          self.supported_versions.get_versions
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
          self.class.new(Middleware::Authenticated.new(self.delegate, credentials), self.reference, self.headers)
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

        # @returns [SSOLoginRedirect] where to send the user to sign in with a provider.
        def sso_login_redirect
          api::SSOLoginRedirect.for(self)
        end

        # Where to send the user's browser to sign in, with one provider or with any.
        #
        # @parameter redirect_url [String] where the homeserver returns the user afterwards.
        # @parameter idp_id [String | nil] the provider the user chose, if they chose one.
        # @returns [String] the URL to open.
        def sso_login_url(redirect_url, idp_id: nil, **options)
          redirect = self.sso_login_redirect

          if idp_id
            redirect.redirect_to_idp(idp_id, redirect_url, **options)
          else
            redirect.redirect_to_sso(redirect_url, **options)
          end
        end

        # The token a single sign on redirect carried.
        #
        # @parameter redirect [String] the query string or URL the user was returned to.
        # @returns [String] the login token.
        # @raises [RequestError] if the redirect carried no token.
        def self.login_token_from(redirect)
          query = redirect.split("?", 2).last.to_s.split("#", 2).first.to_s
          token = ::Protocol::URL::Encoding.decode(query)["loginToken"]

          unless token
            raise RequestError.new(0, "M_MISSING_PARAM", "The redirect carried no login token!")
          end

          token
        end

        # Log in with a single use token, which is how single sign on and `generate_login_token` end.
        #
        # @parameter token [String] the login token.
        # @returns [Login] the login response, which carries the access token.
        def login_with_token(token, **payload)
          payload[:type] = "m.login.token"
          payload[:token] = token

          api::Login.post(self.with(path: "#{V3}/login"), payload)
        end

        # Log in with a single use token, and derive an authenticated client from the result.
        #
        # @parameter token [String] the login token.
        # @returns [Client] an authenticated client.
        def logged_in_with_token(token, **options)
          login = self.login_with_token(token, **options)

          self.authenticated(login.access_token)
        end

        # Finish a single sign on login, from the redirect the user came back with.
        #
        # @parameter redirect [String] the query string or URL the user was returned to.
        # @returns [Client] an authenticated client.
        def logged_in_with_sso(redirect, **options)
          self.logged_in_with_token(self.class.login_token_from(redirect), **options)
        end

        # @returns [LoginToken] the issuer of a token which logs another client in.
        def login_token
          api::LoginToken.for(self)
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
        # @parameter via [Array(String) | nil] the servers to attempt the join through.
        # @returns [Room] the joined room.
        def join_room(id_or_alias, via: nil, **payload)
          path = "#{V3}/join/#{::Protocol::URL::Encoding.escape(id_or_alias)}"
          parameters = {self.join_via_parameter => via}.compact

          joined = api::RoomReference.post(self.with(path: path, parameters: parameters), payload)

          self.room(joined.room_id)
        end

        # The parameter naming the servers to join through.
        #
        # @returns [Symbol] the parameter name.
        def join_via_parameter
          :via
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

        # @returns [Registration] registering an account.
        def registration
          api::Registration.for(self)
        end

        # @returns [PasswordManagement] changing this user's password.
        def password_management
          api::PasswordManagement.for(self)
        end

        # @returns [AccountDeactivation] deactivating this user's account.
        def account_deactivation
          api::AccountDeactivation.for(self)
        end

        # @returns [AdministrativeContact] the email addresses and phone numbers on this account.
        def administrative_contact
          api::AdministrativeContact.for(self)
        end

        # @returns [Admin] what the homeserver will tell an administrator.
        def admin
          api::Admin.for(self)
        end

        # @returns [Users] the user directory.
        def users
          api::Users.for(self)
        end

        # @returns [Banning] banning a user from a room, and lifting it.
        def banning
          api::Banning.for(self)
        end

        # @returns [Kicking] removing a user from a room.
        def kicking
          api::Kicking.for(self)
        end

        # @returns [Inviting] inviting a user to a room.
        def inviting
          api::Inviting.for(self)
        end

        # @returns [ThirdPartyMembership] inviting someone by an address.
        def third_party_membership
          api::ThirdPartyMembership.for(self)
        end

        # @returns [Knocking] knocking on a room.
        def knocking
          api::Knocking.for(self)
        end

        # @returns [Redaction] redacting an event.
        def redaction
          api::Redaction.for(self)
        end

        # @returns [RoomUpgrades] upgrading a room.
        def room_upgrades
          api::RoomUpgrades.for(self)
        end

        # @returns [EventContext] the events around an event.
        def event_context
          api::EventContext.for(self)
        end

        # @returns [RoomInitialSync] a room's state and recent events together.
        def room_initial_sync
          api::RoomInitialSync.for(self)
        end

        # @returns [PeekingEvents] reading a room without joining it.
        def peeking_events
          api::PeekingEvents.for(self)
        end

        # @returns [AccountData] this user's own data, which the homeserver keeps but does not read.
        def account_data
          api::AccountData.for(self)
        end

        # @returns [Tags] the tags this user has put on their rooms.
        def tags
          api::Tags.for(self)
        end

        # @returns [Filter] the filters which narrow what a sync returns.
        def filter
          api::Filter.for(self)
        end

        # @returns [Presence] whether a user is around.
        def presence
          api::Presence.for(self)
        end

        # @returns [Receipts] saying how far this user has read.
        def receipts
          api::Receipts.for(self)
        end

        # @returns [ReadMarkers] where this user has read up to.
        def read_markers
          api::ReadMarkers.for(self)
        end

        # @returns [Directory] the aliases which name a room readably.
        def directory
          api::Directory.for(self)
        end

        # @returns [ListPublicRooms] the rooms a homeserver publishes.
        def list_public_rooms
          api::ListPublicRooms.for(self)
        end

        # @returns [Notifications] the notifications waiting for this user.
        def notifications
          api::Notifications.for(self)
        end

        # @returns [OpenID] a token which proves to another service who this user is.
        def openid
          api::OpenID.for(self)
        end

        # @returns [VOIP] the TURN server a call should go through.
        def voip
          api::VOIP.for(self)
        end

        # @returns [SupportedVersions] the specification versions this homeserver implements.
        def supported_versions
          api::SupportedVersions.for(self)
        end

        # @returns [Wellknown] where a client should look for the homeserver.
        def wellknown
          api::Wellknown.for(self)
        end

        # @returns [Search] searching the events of this user's rooms.
        def search
          api::Search.for(self)
        end

        # @returns [Pusher] the pushers which tell this user's devices about events.
        def pusher
          api::Pusher.for(self)
        end

        # @returns [OldSync] the synchronisation the specification deprecated.
        def old_sync
          api::OldSync.for(self)
        end

        # @returns [ThirdPartyLookup] the networks this homeserver bridges to.
        def third_party_lookup
          api::ThirdPartyLookup.for(self)
        end

        # @returns [Support] who to contact about this homeserver.
        def support
          api::Support.for(self)
        end

        # @returns [RoomSummary] what the homeserver says about a room without joining it.
        def room_summary
          api::RoomSummary.for(self)
        end

        # @returns [SpaceHierarchy] the rooms a space holds.
        def space_hierarchy
          api::SpaceHierarchy.for(self)
        end

        # @returns [ThreadsList] the threads of a room.
        def threads_list
          api::ThreadsList.for(self)
        end

        # @returns [Relations] the events which relate to an event.
        def relations
          api::Relations.for(self)
        end

        # @returns [RegistrationTokens] whether a registration token may still be used.
        def registration_tokens
          api::RegistrationTokens.for(self)
        end

        # @returns [LoginToken] a token which logs a user in once.
        def login_token
          api::LoginToken.for(self)
        end

        # @returns [ReportContent] reporting an event, a room or a user.
        def report_content
          api::ReportContent.for(self)
        end

        # @returns [AppservicePing] pinging an application service.
        def appservice_ping
          api::AppservicePing.for(self)
        end

        # @returns [AppserviceRoomDirectory] whether a bridged room is published.
        def appservice_room_directory
          api::AppserviceRoomDirectory.for(self)
        end

        # @returns [PolicyServer] the policy server a room may check events with.
        def policy_server
          api::PolicyServer.for(self)
        end

        # @returns [MutualRooms] the rooms this user shares with another.
        def mutual_rooms
          api::MutualRooms.for(self)
        end

        # @returns [PushRules] the rules which decide what raises a notification.
        def pushrules
          api::PushRules.for(self)
        end

        # @returns [ContentRepo] the files this homeserver holds.
        def content_repo
          api::ContentRepo.for(self)
        end

        # @returns [AuthedContentRepo] the files this homeserver holds, asked for with an access token.
        def authed_content_repo
          api::AuthedContentRepo.for(self)
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
