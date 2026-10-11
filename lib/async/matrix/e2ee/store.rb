# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module E2EE
      # What a device remembers between syncs, held in memory.
      #
      # A client which must survive a restart gives the machine its own store instead.
      class Store
        def initialize
          @sessions = {}
          @withheld = {}
          @pending = {}
        end

        # @attribute [Hash] the sessions which were shared with us, by room and session ID.
        attr :sessions

        # @attribute [Hash] why a session was refused, by room and session ID.
        attr :withheld

        # Remember a session another device shared.
        #
        # @parameter room_id [String] the room the session is for.
        # @parameter session_id [String] the ID of the session.
        # @parameter sender [String] the user who shared it.
        def remember(room_id, session_id:, sender:)
          @sessions[[room_id, session_id]] = {sender: sender, at: Time.now}
        end

        # @parameter room_id [String] the room.
        # @parameter session_id [String] the session.
        # @returns [Boolean] whether we hold it.
        def session?(room_id, session_id)
          @sessions.key?([room_id, session_id])
        end

        # Remember that a session was deliberately not shared.
        #
        # @parameter room_id [String] the room.
        # @parameter session_id [String] the session.
        # @parameter code [String] the reason the sender gave, e.g. `m.unverified`.
        def refuse(room_id, session_id:, code:)
          @withheld[[room_id, session_id]] = code
        end

        # @parameter room_id [String] the room.
        # @parameter session_id [String] the session.
        # @returns [String | nil] the reason it was refused.
        def refused(room_id, session_id)
          @withheld[[room_id, session_id]]
        end

        # Keep an event which cannot be read yet, so it can be read when its key arrives.
        #
        # @parameter room_id [String] the room.
        # @parameter session_id [String] the session the event needs.
        # @parameter event [Async::Matrix::Events::Envelope] the event.
        def defer(room_id, session_id:, event:)
          (@pending[[room_id, session_id]] ||= []) << event
        end

        # The events which were waiting for a session, which are no longer waiting.
        #
        # @parameter room_id [String] the room.
        # @parameter session_id [String] the session which arrived.
        # @returns [Array(Async::Matrix::Events::Envelope)] the events.
        def deferred(room_id, session_id)
          @pending.delete([room_id, session_id]) || []
        end

        # @returns [Integer] how many events are waiting for a key.
        def deferred_count
          @pending.each_value.sum(&:size)
        end
      end
    end
  end
end
