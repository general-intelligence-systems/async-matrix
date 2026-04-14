class DeviceListsOutboundLastSuccess < Sequel::Model(:device_lists_outbound_last_success)
  unrestrict_primary_key
  set_primary_key [:destination, :user_id]
end
