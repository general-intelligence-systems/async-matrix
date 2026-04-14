# frozen_string_literal: true

# POST /_matrix/identity/v2/store-invite
# Auth: yes | Rate-limited: no
# Response: 200, 400, 403
module MatrixApi
  module Identity
    module V2
      class StoreInvite < Base
        desc 'Store a pending third-party invite.' do
          detail 'Stores pending invitations to a user\'s 3PID. Generates a token and ephemeral key.'
          failure [
            [400, '3PID already bound or medium unsupported (M_THREEPID_IN_USE, M_UNRECOGNIZED)'],
            [403, 'Must accept terms (M_TERMS_NOT_SIGNED)']
          ]
        end
        params do
          requires :address, type: String, desc: 'The email address of the invited user'
          requires :medium, type: String, desc: 'The literal string "email"'
          requires :room_id, type: String, desc: 'The room ID to invite to'
          requires :sender, type: String, desc: 'The Matrix user ID of the inviting user'
          optional :room_alias, type: String, desc: 'Canonical room alias'
          optional :room_avatar_url, type: String, desc: 'Room avatar MXC URI'
          optional :room_join_rules, type: String, desc: 'Room join rules'
          optional :room_name, type: String, desc: 'Room name'
          optional :room_type, type: String, desc: 'Room type from m.room.create'
          optional :sender_avatar_url, type: String, desc: 'Inviter avatar MXC URI'
          optional :sender_display_name, type: String, desc: 'Inviter display name'
        end
        post do
          authenticate!
          # TODO: implement
          status 200
        end
      end
    end
  end
end
