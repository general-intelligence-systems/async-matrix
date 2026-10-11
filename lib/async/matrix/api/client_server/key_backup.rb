# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/key_backup"

module Async
  module Matrix
    module ClientServer
      # The backup a new version was created as.
      class KeyBackupReference < Representation
        include Versioned

        # @returns [String] the version which was created.
        def version
          self.value[:version]
        end
      end

      # One version of a key backup, and what the server holds for it.
      class KeyBackupVersion < Representation
        include Versioned

        # @returns [String] the version.
        def version
          self.value[:version]
        end

        # @returns [String] the algorithm the sessions are encrypted with.
        def algorithm
          self.value[:algorithm]
        end

        # @returns [Hash] what the algorithm needs in order to be used.
        def auth_data
          self.value[:auth_data]
        end

        # @returns [Integer | nil] how many sessions are backed up.
        def count
          self.value[:count]
        end

        # @returns [String | nil] the opaque tag which changes when the backup does.
        def etag
          self.value[:etag]
        end
      end

      # What the server holds after a backup was written to or deleted from.
      class KeyBackupUpdate < Representation
        include Versioned

        # @returns [Integer] how many sessions are backed up.
        def count
          self.value[:count]
        end

        # @returns [String] the opaque tag which changes when the backup does.
        def etag
          self.value[:etag]
        end
      end

      # The backed up sessions of every room.
      class BackedUpRoomKeys < Representation
        include Versioned

        # @returns [Hash] the rooms, by room ID.
        def rooms
          self.value[:rooms] || {}
        end

        # @parameter room_id [String] the room to look up.
        # @returns [Hash] that room's sessions, by session ID.
        def sessions_of(room_id)
          self.rooms.dig(room_id.to_sym, :sessions) || {}
        end
      end

      # The backed up sessions of one room.
      class BackedUpSessions < Representation
        include Versioned

        # @returns [Hash] the sessions, by session ID.
        def sessions
          self.value[:sessions] || {}
        end

        # @returns [Array(String)] the ID of each session.
        def ids
          self.sessions.keys.map(&:to_s)
        end
      end

      # One backed up session, whose key material is encrypted.
      class BackedUpSession < Representation
        include Versioned

        # @returns [Integer] the index of the first message this session can decrypt.
        def first_message_index
          self.value[:first_message_index]
        end

        # @returns [Integer] how many times the key was forwarded to reach us.
        def forwarded_count
          self.value[:forwarded_count]
        end

        # @returns [Boolean] whether the device it came from was verified.
        def verified?
          self.value[:is_verified] || false
        end

        # @returns [Hash] the encrypted key material, which only the backup key opens.
        def session_data
          self.value[:session_data]
        end
      end

      # The keys held in one version of a backup.
      #
      # Every request names the version, so it is carried here rather than passed each time.
      class BackupKeys
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @parameter version [String] the backup version to read and write.
        # @returns [BackupKeys] the keys.
        def self.for(parent, version)
          self.new(parent, version)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        # @parameter version [String] the backup version.
        def initialize(resource, version)
          @resource = resource
          @version = version
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # @attribute [String] the backup version.
        attr :version

        def inspect
          "\#<#{self.class} #{@version}>"
        end

        # @returns [BackedUpRoomKeys] every session in this version.
        def get_room_keys
          api::BackedUpRoomKeys.get(self.keys)
        end

        # Replace the sessions of every room.
        #
        # @parameter rooms [Hash] the rooms to write, by room ID.
        # @returns [KeyBackupUpdate] what the server now holds.
        def put_room_keys(rooms)
          api::KeyBackupUpdate.put(self.keys, {rooms: rooms})
        end

        # @returns [KeyBackupUpdate] what the server now holds.
        def delete_room_keys
          api::KeyBackupUpdate.delete(self.keys)
        end

        # @parameter room_id [String] the room to read.
        # @returns [BackedUpSessions] that room's sessions.
        def get_room_keys_by_room_id(room_id)
          api::BackedUpSessions.get(self.keys(room_id))
        end

        # Replace the sessions of one room.
        #
        # @parameter room_id [String] the room to write.
        # @parameter sessions [Hash] the sessions, by session ID.
        # @returns [KeyBackupUpdate] what the server now holds.
        def put_room_keys_by_room_id(room_id, sessions)
          api::KeyBackupUpdate.put(self.keys(room_id), {sessions: sessions})
        end

        # @parameter room_id [String] the room to delete.
        # @returns [KeyBackupUpdate] what the server now holds.
        def delete_room_keys_by_room_id(room_id)
          api::KeyBackupUpdate.delete(self.keys(room_id))
        end

        # @parameter room_id [String] the room the session belongs to.
        # @parameter session_id [String] the session to read.
        # @returns [BackedUpSession] the session.
        def get_room_key_by_session_id(room_id, session_id)
          api::BackedUpSession.get(self.keys(room_id, session_id))
        end

        # Write one session.
        #
        # @parameter room_id [String] the room the session belongs to.
        # @parameter session_id [String] the session to write.
        # @parameter session_data [Hash] the encrypted key material.
        # @parameter first_message_index [Integer] the first message it decrypts.
        # @parameter forwarded_count [Integer] how many times it was forwarded.
        # @parameter is_verified [Boolean] whether it came from a verified device.
        # @returns [KeyBackupUpdate] what the server now holds.
        def put_room_key_by_session_id(room_id, session_id, session_data:, first_message_index: 0, forwarded_count: 0, is_verified: false)
          payload = {
            session_data: session_data,
            first_message_index: first_message_index,
            forwarded_count: forwarded_count,
            is_verified: is_verified,
          }

          api::KeyBackupUpdate.put(self.keys(room_id, session_id), payload)
        end

        # @parameter room_id [String] the room the session belongs to.
        # @parameter session_id [String] the session to delete.
        # @returns [KeyBackupUpdate] what the server now holds.
        def delete_room_key_by_session_id(room_id, session_id)
          api::KeyBackupUpdate.delete(self.keys(room_id, session_id))
        end

        private

        # The resource of the keys, narrowed to a room and a session when they are given.
        #
        # @parameter room_id [String | nil] the room.
        # @parameter session_id [String | nil] the session.
        # @returns [Async::REST::Resource] the resource.
        def keys(room_id = nil, session_id = nil)
          path = "#{V3}/room_keys/keys"

          if room_id
            path += "/#{::Protocol::URL::Encoding.escape(room_id)}"
          end

          if session_id
            path += "/#{::Protocol::URL::Encoding.escape(session_id)}"
          end

          @resource.with(path: path, parameters: {version: @version})
        end
      end

      # The versions of this user's key backup.
      #
      # The sessions are encrypted with a key this library never sees.
      class KeyBackup
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [KeyBackup] the backup.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        def inspect
          "\#<#{self.class}>"
        end

        # Create a version to back sessions up to.
        #
        # @parameter algorithm [String] how the sessions are encrypted.
        # @parameter auth_data [Hash] what the algorithm needs in order to be used.
        # @returns [KeyBackupReference] the version which was created.
        def post_room_keys_version(algorithm:, auth_data:)
          payload = {algorithm: algorithm, auth_data: auth_data}

          api::KeyBackupReference.post(@resource.with(path: "#{V3}/room_keys/version"), payload)
        end

        # @returns [KeyBackupVersion] the version the server would have a client use.
        def get_room_keys_version_current
          api::KeyBackupVersion.get(@resource.with(path: "#{V3}/room_keys/version"))
        end

        # @parameter version [String] the version to look up.
        # @returns [KeyBackupVersion] that version.
        def get_room_keys_version(version)
          api::KeyBackupVersion.get(@resource.with(path: self.path_for(version)))
        end

        # Replace a version's algorithm and authentication data.
        #
        # @parameter version [String] the version to update.
        # @parameter algorithm [String] how the sessions are encrypted.
        # @parameter auth_data [Hash] what the algorithm needs in order to be used.
        # @returns [Representation] the empty response.
        def put_room_keys_version(version, algorithm:, auth_data:)
          payload = {algorithm: algorithm, auth_data: auth_data, version: version}

          api::Representation.put(@resource.with(path: self.path_for(version)), payload)
        end

        # Delete a version, and every session backed up to it.
        #
        # @parameter version [String] the version to delete.
        # @returns [Representation] the empty response.
        def delete_room_keys_version(version)
          api::Representation.delete(@resource.with(path: self.path_for(version)))
        end

        # @parameter version [String] the version to read and write.
        # @returns [BackupKeys] the keys held in that version.
        def keys(version)
          api::BackupKeys.for(@resource, version)
        end

        private

        # @parameter version [String] the version.
        # @returns [String] the path of one version.
        def path_for(version)
          "#{V3}/room_keys/version/#{::Protocol::URL::Encoding.escape(version)}"
        end
      end
    end
  end
end
