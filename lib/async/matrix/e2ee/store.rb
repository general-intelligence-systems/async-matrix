# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

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
        # Whatever else is known about it is kept too, since a backup or an export carries more than the key.
        #
        # @parameter room_id [String] the room the session is for.
        # @parameter session_id [String] the ID of the session.
        # @parameter sender [String | nil] the user who shared it.
        # @parameter rest [Hash] what else is known: whether it was imported, what index it begins at.
        def remember(room_id, session_id:, sender:, **rest)
          @sessions[[room_id, session_id]] = {sender: sender, at: Time.now, **rest}
        end

        # Which device shared a session, where that was known when it arrived.
        #
        # @parameter session_id [String] the session.
        # @returns [String | nil] the device ID.
        def sender_device(session_id)
          found = @sessions.find{|(_, held), _| held == session_id}

          found&.last&.fetch(:device_id, nil)
        end

        # The earliest index a session can still be read from, which is what it exports at.
        #
        # @parameter room_id [String] the room.
        # @parameter session_id [String] the session.
        # @returns [Integer] the index.
        def first_known_index(room_id, session_id)
          @sessions.dig([room_id, session_id], :first_known_index) || 0
        end

        # Whether a session was imported rather than shared with us directly.
        #
        # @parameter session_id [String] the session.
        # @returns [Boolean] whether it carries no signature of its own.
        def imported?(session_id)
          @sessions.any?{|(_, held), session| held == session_id and session[:imported]}
        end

        # When a room's own session was begun, which is what its age is measured from.
        #
        # @parameter room_id [String] the room.
        # @returns [Time | nil] when it began, if a session of ours was.
        def started(room_id)
          @started ||= {}
          @started[room_id]
        end

        # Note that a session of our own has begun for this room.
        #
        # @parameter room_id [String] the room.
        # @parameter at [Time] when it began.
        def starting(room_id, at: Time.now)
          @started ||= {}
          @started[room_id] = at
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
