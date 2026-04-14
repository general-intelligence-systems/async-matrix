class DeviceAuthProvider < Sequel::Model(:device_auth_providers)
  unrestrict_primary_key

  many_to_one :device, key: [:user_id, :device_id]
end
