class RoomMembership < Sequel::Model(:room_memberships)
  unrestrict_primary_key

  many_to_one :room
  many_to_one :user, key: :user_id, primary_key: :name
  many_to_one :event
end
