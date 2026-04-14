class BlockedRoom < Sequel::Model(:blocked_rooms)
  unrestrict_primary_key
  set_primary_key :room_id
end
