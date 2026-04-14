Sequel.migration do
  change do
    create_table(:device_auth_providers) do
      Text :user_id, null: false
      Text :device_id, null: false
      Text :auth_provider_id, null: false
      Text :auth_provider_session_id, null: false

      index [:user_id, :device_id], name: :device_auth_providers_devices
      index [:auth_provider_id, :auth_provider_session_id], name: :device_auth_providers_sessions
    end
  end
end
