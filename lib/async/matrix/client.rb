# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/rest/resource"

require "protocol/url/encoding"

require_relative "version"
require_relative "paths"
require_relative "representation"
require_relative "session"
require_relative "rooms"
require_relative "sync"

module Async
	module Matrix
		# A client for the Matrix client-server API.
		#
		# The client is rooted at the homeserver rather than at a versioned base path, because the API
		# is versioned per-endpoint. An unauthenticated client can discover the server's capabilities
		# and log in; {#authenticated} derives a client which carries an access token.
		class Client < Async::REST::Resource
			# The default homeserver to connect to.
			ENDPOINT = Async::HTTP::Endpoint.parse("http://localhost:8008")
			
			# The user agent supplied with every request.
			USER_AGENT = "async-matrix/#{VERSION}"
			
			# @returns [Representation] the specification versions supported by the homeserver.
			def versions
				Representation.get(self.with(path: "/_matrix/client/versions"))
			end
			
			# Derive a client which authenticates using the given access token.
			#
			# @parameter access_token [String] the access token obtained from {#login}.
			# @returns [Client] an authenticated client.
			def authenticated(access_token)
				self.with(headers: {
					"authorization" => "Bearer #{access_token}",
					"user-agent" => USER_AGENT,
				})
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
				
				Login.post(self.with(path: "#{V3}/login"), payload)
			end
			
			# Log in using a password, and derive an authenticated client from the result.
			#
			# @parameter user [String] the localpart or fully qualified ID of the user.
			# @parameter password [String] the user's password.
			# @returns [Client] an authenticated client.
			def logged_in(user, password, **options)
				login = self.login(user, password, **options)
				
				# Note: the login representation shares this client's connection, so it must not be
				# closed here - see {Client#close}.
				return self.authenticated(login.access_token)
			end
			
			# @returns [Whoami] the identity associated with this client's access token.
			def whoami
				Whoami.get(self.with(path: "#{V3}/account/whoami"))
			end
			
			# @returns [JoinedRooms] the rooms this user has joined.
			def joined_rooms
				JoinedRooms.new(self.with(path: "#{V3}/joined_rooms"))
			end
			
			# A room, by ID. No request is made.
			#
			# @parameter id [String] the room ID, e.g. `!abc:localhost`.
			# @returns [Room] the room.
			def room(id)
				Room.for(self, id)
			end
			
			# Create a room.
			#
			# @parameter payload [Hash] the room creation options, e.g. `name:`, `topic:`, `preset:`.
			# @returns [Room] the created room.
			def create_room(**payload)
				created = RoomReference.post(self.with(path: "#{V3}/createRoom"), payload)
				
				return self.room(created.room_id)
			end
			
			# Join a room, by ID or alias.
			#
			# @parameter id_or_alias [String] the room ID or alias, e.g. `#general:localhost`.
			# @returns [Room] the joined room.
			def join(id_or_alias, **payload)
				path = "#{V3}/join/#{::Protocol::URL::Encoding.escape(id_or_alias)}"
				
				joined = RoomReference.post(self.with(path: path), payload)
				
				return self.room(joined.room_id)
			end
			
			# Begin syncing.
			#
			# @parameter since [String | nil] the batch token to start from, or nil for the initial sync.
			# @parameter timeout [Integer] how long the server should wait, in milliseconds.
			# @returns [Sync] the first batch.
			def sync(since: nil, timeout: Sync::DEFAULT_TIMEOUT, **parameters)
				Sync.start(self, since: since, timeout: timeout, **parameters)
			end
		end
	end
end
