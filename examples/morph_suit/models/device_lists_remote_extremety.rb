class DeviceListsRemoteExtremety < Sequel::Model(:device_lists_remote_extremeties)
  unrestrict_primary_key
  set_primary_key :user_id
end
