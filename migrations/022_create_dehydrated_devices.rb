Sequel.migration do
  change do
    create_table(:dehydrated_devices) do
      Text :user_id, primary_key: true
      Text :device_id, null: false
      Text :device_data, null: false
    end
  end
end
