# frozen_string_literal: true

# /_matrix/client/v3/rooms/:roomId/*
# Covers: events, state, members, messages, send, redact, membership,
#         typing, receipts, read_markers, reporting, context, upgrade
module MatrixApi
  module Client
    module V3
      class Rooms < Base
        route_param :roomId, type: String, desc: 'The room ID' do

          # ==================================================================
          # Event Reading
          # ==================================================================

          # GET /rooms/:roomId/event/:eventId
          # Auth: yes | Rate-limited: no | Response: 200, 404
          desc 'Get a single event by event ID.' do
            failure [[404, 'Event not found']]
          end
          get 'event/:eventId' do
            authenticate!
            # TODO: implement
            status 200
          end

          # GET /rooms/:roomId/state
          # Auth: yes | Rate-limited: no | Response: 200, 403
          desc 'Get all current state events in a room.' do
            failure [[403, 'Forbidden (not in room)']]
          end
          get :state do
            authenticate!
            # TODO: implement
            status 200
          end

          # GET /rooms/:roomId/state/:eventType/:stateKey
          # Auth: yes | Rate-limited: no | Response: 200, 403, 404
          desc 'Get a specific state event.' do
            failure [
              [403, 'Forbidden'],
              [404, 'State event not found']
            ]
          end
          get 'state/:eventType/:stateKey' do
            authenticate!
            # TODO: implement
            status 200
          end

          # GET /rooms/:roomId/members
          # Auth: yes | Rate-limited: no | Response: 200, 403
          desc 'Get the member list for a room.' do
            failure [[403, 'Forbidden']]
          end
          params do
            optional :at, type: String, desc: 'Point-in-time pagination token'
            optional :membership, type: String, desc: 'Filter by membership type'
            optional :not_membership, type: String, desc: 'Exclude by membership type'
          end
          get :members do
            authenticate!
            # TODO: implement
            status 200
          end

          # GET /rooms/:roomId/joined_members
          # Auth: yes | Rate-limited: no | Response: 200, 403
          desc 'Get the joined members list for a room.' do
            failure [[403, 'Forbidden']]
          end
          get :joined_members do
            authenticate!
            # TODO: implement
            status 200
          end

          # GET /rooms/:roomId/messages
          # Auth: yes | Rate-limited: no | Response: 200, 403
          desc 'Get a list of message and state events for a room.' do
            failure [[403, 'Forbidden']]
          end
          params do
            requires :from, type: String, desc: 'Pagination token to start from'
            optional :to, type: String, desc: 'Pagination token to stop at'
            requires :dir, type: String, values: %w[b f], desc: 'Direction: b(ackwards) or f(orwards)'
            optional :limit, type: Integer, desc: 'Maximum number of events to return'
            optional :filter, type: String, desc: 'RoomEventFilter as JSON string'
          end
          get :messages do
            authenticate!
            # TODO: implement
            status 200
          end

          # GET /rooms/:roomId/aliases
          # Auth: yes | Rate-limited: yes | Response: 200, 403, 429
          desc 'Get a list of aliases for a room.' do
            failure [
              [403, 'Forbidden'],
              [429, 'Rate limited (M_LIMIT_EXCEEDED)']
            ]
          end
          get :aliases do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # ==================================================================
          # Event Sending
          # ==================================================================

          # PUT /rooms/:roomId/state/:eventType/:stateKey
          # Auth: yes | Rate-limited: no | Response: 200, 400, 403, 409
          desc 'Send a state event to a room.' do
            failure [
              [400, 'Bad request'],
              [403, 'Forbidden'],
              [409, 'Conflict']
            ]
          end
          put 'state/:eventType/:stateKey' do
            authenticate!
            # TODO: implement
            status 200
          end

          # PUT /rooms/:roomId/send/:eventType/:txnId
          # Auth: yes | Rate-limited: no | Response: 200, 400, 403
          desc 'Send a message event to a room.' do
            failure [
              [400, 'Bad request'],
              [403, 'Forbidden']
            ]
          end
          put 'send/:eventType/:txnId' do
            authenticate!
            # TODO: implement
            status 200
          end

          # PUT /rooms/:roomId/redact/:eventId/:txnId
          # Auth: yes | Rate-limited: no | Response: 200, 400, 403
          desc 'Redact an event.' do
            failure [
              [400, 'Bad request'],
              [403, 'Forbidden']
            ]
          end
          params do
            optional :reason, type: String, desc: 'Reason for redacting the event'
          end
          put 'redact/:eventId/:txnId' do
            authenticate!
            # TODO: implement
            status 200
          end

          # ==================================================================
          # Membership
          # ==================================================================

          # POST /rooms/:roomId/invite
          # Auth: yes | Rate-limited: yes | Response: 200, 400, 403, 429
          desc 'Invite a user to a room.' do
            failure [
              [400, 'Bad request'],
              [403, 'Forbidden'],
              [429, 'Rate limited']
            ]
          end
          params do
            requires :user_id, type: String, desc: 'The user ID to invite'
            optional :reason, type: String, desc: 'Reason for the invite'
          end
          post :invite do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # POST /rooms/:roomId/join
          # Auth: yes | Rate-limited: yes | Response: 200, 400, 403, 429
          desc 'Join a room by room ID.' do
            failure [
              [400, 'Bad request'],
              [403, 'Forbidden'],
              [429, 'Rate limited']
            ]
          end
          params do
            optional :reason, type: String, desc: 'Reason for joining'
            optional :third_party_signed, type: Hash, desc: 'Third-party signed invite token'
          end
          post :join do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # POST /rooms/:roomId/leave
          # Auth: yes | Rate-limited: yes | Response: 200, 429
          desc 'Leave a room.' do
            failure [[429, 'Rate limited']]
          end
          params do
            optional :reason, type: String, desc: 'Reason for leaving'
          end
          post :leave do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # POST /rooms/:roomId/forget
          # Auth: yes | Rate-limited: yes | Response: 200, 400, 429
          desc 'Forget a room.' do
            failure [
              [400, 'Bad request (not left the room)'],
              [429, 'Rate limited']
            ]
          end
          post :forget do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # POST /rooms/:roomId/kick
          # Auth: yes | Rate-limited: no | Response: 200, 403
          desc 'Kick a user from a room.' do
            failure [[403, 'Forbidden']]
          end
          params do
            requires :user_id, type: String, desc: 'The user ID to kick'
            optional :reason, type: String, desc: 'Reason for the kick'
          end
          post :kick do
            authenticate!
            # TODO: implement
            status 200
          end

          # POST /rooms/:roomId/ban
          # Auth: yes | Rate-limited: no | Response: 200, 403
          desc 'Ban a user from a room.' do
            failure [[403, 'Forbidden']]
          end
          params do
            requires :user_id, type: String, desc: 'The user ID to ban'
            optional :reason, type: String, desc: 'Reason for the ban'
          end
          post :ban do
            authenticate!
            # TODO: implement
            status 200
          end

          # POST /rooms/:roomId/unban
          # Auth: yes | Rate-limited: no | Response: 200, 403
          desc 'Unban a user from a room.' do
            failure [[403, 'Forbidden']]
          end
          params do
            requires :user_id, type: String, desc: 'The user ID to unban'
            optional :reason, type: String, desc: 'Reason for the unban'
          end
          post :unban do
            authenticate!
            # TODO: implement
            status 200
          end

          # ==================================================================
          # Typing, Receipts, Read Markers
          # ==================================================================

          # PUT /rooms/:roomId/typing/:userId
          # Auth: yes | Rate-limited: yes | Response: 200, 429
          desc 'Inform the server of typing status.' do
            failure [[429, 'Rate limited']]
          end
          params do
            requires :typing, type: Boolean, desc: 'Whether the user is typing'
            optional :timeout, type: Integer, desc: 'Typing timeout in ms (required when typing=true)'
          end
          put 'typing/:userId' do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # POST /rooms/:roomId/receipt/:receiptType/:eventId
          # Auth: yes | Rate-limited: yes | Response: 200, 400, 429
          desc 'Send a receipt for an event.' do
            failure [
              [400, 'Bad request'],
              [429, 'Rate limited']
            ]
          end
          params do
            optional :thread_id, type: String, desc: 'Thread ID for threaded receipts (added v1.4)'
          end
          post 'receipt/:receiptType/:eventId' do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # POST /rooms/:roomId/read_markers
          # Auth: yes | Rate-limited: yes | Response: 200, 429
          desc 'Set read markers.' do
            failure [[429, 'Rate limited']]
          end
          params do
            optional :m_fully_read, type: String, desc: 'Event ID for the fully-read marker'
            optional :m_read, type: String, desc: 'Event ID for the read receipt'
            optional :m_read_private, type: String, desc: 'Event ID for private read receipt (added v1.4)'
          end
          post :read_markers do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # ==================================================================
          # Context
          # ==================================================================

          # GET /rooms/:roomId/context/:eventId
          # Auth: yes | Rate-limited: no | Response: 200, 404
          desc 'Get events around a given event.' do
            failure [[404, 'Event not found']]
          end
          params do
            optional :limit, type: Integer, desc: 'Max number of events on each side'
            optional :filter, type: String, desc: 'RoomEventFilter as JSON string'
          end
          get 'context/:eventId' do
            authenticate!
            # TODO: implement
            status 200
          end

          # ==================================================================
          # Reporting
          # ==================================================================

          # POST /rooms/:roomId/report
          # Auth: yes | Rate-limited: yes | Added v1.18 | Response: 200, 404, 429
          desc 'Report a room.' do
            failure [
              [404, 'Room not found'],
              [429, 'Rate limited']
            ]
          end
          params do
            requires :reason, type: String, desc: 'The reason for the report'
          end
          post :report do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # POST /rooms/:roomId/report/:eventId
          # Auth: yes | Rate-limited: yes | Response: 200, 404, 429
          desc 'Report an event.' do
            failure [
              [404, 'Event not found'],
              [429, 'Rate limited']
            ]
          end
          params do
            optional :reason, type: String, desc: 'Reason for the report'
            optional :score, type: Integer, desc: 'Score -100 to 0 (deprecated)'
          end
          post 'report/:eventId' do
            authenticate!
            rate_limit!
            # TODO: implement
            status 200
          end

          # ==================================================================
          # Room Upgrade
          # ==================================================================

          # POST /rooms/:roomId/upgrade
          # Auth: yes | Rate-limited: no | Response: 200, 400, 403
          desc 'Upgrade a room to a new version.' do
            failure [
              [400, 'Bad request (M_UNSUPPORTED_ROOM_VERSION)'],
              [403, 'Forbidden']
            ]
          end
          params do
            requires :new_version, type: String, desc: 'The new room version to upgrade to'
          end
          post :upgrade do
            authenticate!
            # TODO: implement
            status 200
          end

          # GET /rooms/:roomId/initialSync (deprecated)
          # Auth: yes | Rate-limited: no | Response: 200
          desc 'Get initial sync data for a room (deprecated).'
          get :initialSync do
            authenticate!
            # TODO: implement - deprecated
            status 200
          end

        end # route_param :roomId
      end
    end
  end
end
