Sequel.migration do
  change do
    create_table(:e2e_cross_signing_signatures) do
      Text :user_id, null: false
      Text :key_id, null: false
      Text :target_user_id, null: false
      Text :target_device_id, null: false
      Text :signature, null: false

      index [:user_id, :target_user_id, :target_device_id]
    end
  end
end
