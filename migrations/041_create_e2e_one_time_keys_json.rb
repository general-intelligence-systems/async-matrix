Sequel.migration do
  change do
    create_table(:e2e_one_time_keys_json) do
      Text :user_id, null: false
      Text :device_id, null: false
      Text :algorithm, null: false
      Text :key_id, null: false
      Bignum :ts_added_ms, null: false
      Text :key_json, null: false

      unique [:user_id, :device_id, :algorithm, :key_id]
    end
  end
end
