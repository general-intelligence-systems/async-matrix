Sequel.migration do
  change do
    create_table(:server_keys_json) do
      Text :server_name, null: false
      Text :key_id, null: false
      Text :from_server, null: false
      Bignum :ts_added_ms, null: false
      Bignum :ts_valid_until_ms, null: false
      File :key_json, null: false

      unique [:server_name, :key_id, :from_server]
    end
  end
end
