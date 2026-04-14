class DeviceListsRemoteCache < Sequel::Model(:device_lists_remote_cache)
  unrestrict_primary_key
  set_primary_key [:user_id, :device_id]
end
