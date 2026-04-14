class EventEdge < Sequel::Model(:event_edges)
  unrestrict_primary_key

  many_to_one :event, key: :event_id
end
