# frozen_string_literal: true

# POST /_matrix/push/v1/notify
# Auth: no | Rate-limited: no
# Response: 200
module MatrixApi
  module Push
    module V1
      class Notify < Base
        desc 'Notify a push gateway about an event.' do
          detail 'Invoked by HTTP pushers to send push notifications or update unread counts.'
        end
        params do
          requires :notification, type: Hash, desc: 'Notification payload' do
            requires :devices, type: Array, desc: 'Devices to send the notification to (app_id, pushkey required per device)'
            optional :event_id, type: String, desc: 'Matrix event ID (required if about a specific event)'
            optional :room_id, type: String, desc: 'Room ID where the event occurred'
            optional :type, type: String, desc: 'Event type'
            optional :sender, type: String, desc: 'Event sender'
            optional :sender_display_name, type: String, desc: 'Current display name of the sender'
            optional :room_name, type: String, desc: 'Room name'
            optional :room_alias, type: String, desc: 'Room alias'
            optional :prio, type: String, values: %w[high low], desc: 'Notification priority (default: high)'
            optional :content, type: Hash, desc: 'Event content'
            optional :counts, type: Hash, desc: 'Unread counts (unread, missed_calls)'
            optional :user_is_target, type: Boolean, desc: 'True if user is the subject of a member event'
          end
        end
        post do
          # TODO: implement
          status 200
        end
      end
    end
  end
end
