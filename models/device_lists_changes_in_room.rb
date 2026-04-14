class DeviceListsChangesInRoom < Sequel::Model(:device_lists_changes_in_room)
  unrestrict_primary_key
  set_primary_key [:stream_id, :room_id]
end
