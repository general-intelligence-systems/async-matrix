Sequel.migration do
  change do
    create_table(:server_signature_keys) do
      Text :server_name
      Text :key_id
      Text :from_server
      Bignum :ts_added_ms
      File :verify_key
      Bignum :ts_valid_until_ms

      unique [:server_name, :key_id]
    end
  end
end
