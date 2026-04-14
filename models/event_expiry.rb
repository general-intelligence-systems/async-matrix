class EventExpiry < Sequel::Model(:event_expiry)
  unrestrict_primary_key
  set_primary_key :event_id
end
