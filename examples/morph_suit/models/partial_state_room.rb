class PartialStateRoom < Sequel::Model(:partial_state_rooms)
  unrestrict_primary_key
  set_primary_key :room_id
end
