class EventLabel < Sequel::Model(:event_labels)
  unrestrict_primary_key
  set_primary_key [:event_id, :label]
end
