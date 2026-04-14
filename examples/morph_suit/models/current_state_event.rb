class CurrentStateEvent < Sequel::Model(:current_state_events)
  unrestrict_primary_key
  set_primary_key [:room_id, :type, :state_key]

  many_to_one :room, key: :room_id
  many_to_one :event, key: :event_id, primary_key: :event_id
end
