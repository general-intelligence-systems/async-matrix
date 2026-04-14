class RoomRetention < Sequel::Model(:room_retention)
  unrestrict_primary_key
  set_primary_key [:room_id, :event_id]
end
