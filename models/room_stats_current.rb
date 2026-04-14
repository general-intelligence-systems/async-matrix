class RoomStatsCurrent < Sequel::Model(:room_stats_current)
  unrestrict_primary_key
  set_primary_key :room_id
end
