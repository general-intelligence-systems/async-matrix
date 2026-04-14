# frozen_string_literal: true

# POST /_matrix/client/v3/createRoom
# Auth: yes | Rate-limited: yes
# Response: 200, 400, 403
module MatrixApi
  module Client
    module V3
      class CreateRoom < Base
        desc 'Create a new room.' do
          detail 'Create a new room with various configuration options.'
          failure [
            [400, 'Bad request (M_UNKNOWN, M_ROOM_IN_USE, M_INVALID_ROOM_STATE, M_UNSUPPORTED_ROOM_VERSION)'],
            [403, 'Forbidden']
          ]
        end
        params do
          optional :visibility, type: String, values: %w[public private], desc: 'Room directory visibility'
          optional :room_alias_name, type: String, desc: 'Desired room alias local part'
          optional :name, type: String, desc: 'Room name'
          optional :topic, type: String, desc: 'Room topic'
          optional :invite, type: Array[String], desc: 'User IDs to invite'
          optional :invite_3pid, type: Array, desc: 'Third-party invites'
          optional :room_version, type: String, desc: 'The room version to set'
          optional :creation_content, type: Hash, desc: 'Extra keys for m.room.create'
          optional :initial_state, type: Array, desc: 'State events to set'
          optional :preset, type: String, values: %w[private_chat public_chat trusted_private_chat], desc: 'Convenience preset'
          optional :is_direct, type: Boolean, desc: 'Is this a DM room?'
          optional :power_level_content_override, type: Hash, desc: 'Power level content override'
        end
        post do
          authenticate!
          rate_limit!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
