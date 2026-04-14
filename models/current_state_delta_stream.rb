class CurrentStateDeltaStream < Sequel::Model(:current_state_delta_stream)
  unrestrict_primary_key

  many_to_one :room, key: :room_id
end
