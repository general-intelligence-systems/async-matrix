class StateEvent < Sequel::Model(:state_events)
  unrestrict_primary_key

  many_to_one :event
  many_to_one :room
end
