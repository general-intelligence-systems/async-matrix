class EventReport < Sequel::Model(:event_reports)
  many_to_one :room
  many_to_one :event
end
