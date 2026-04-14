class BatchEvent < Sequel::Model(:batch_events)
  unrestrict_primary_key
  set_primary_key :event_id

  many_to_one :event, key: :event_id
  many_to_one :room, key: :room_id
end
