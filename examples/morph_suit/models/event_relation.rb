class EventRelation < Sequel::Model(:event_relations)
  unrestrict_primary_key

  many_to_one :event, key: :event_id
  many_to_one :relates_to_event, class: :Event, key: :relates_to_id
end
