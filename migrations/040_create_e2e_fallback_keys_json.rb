Sequel.migration do
  change do
    create_table(:e2e_fallback_keys_json) do
      Text :user_id, null: false
      Text :device_id, null: false
      Text :algorithm, null: false
      Text :key_id, null: false
      Text :key_json, null: false
      TrueClass :used, default: false, null: false

      unique [:user_id, :device_id, :algorithm]
    end
  end
end
