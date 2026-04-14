Sequel.migration do
  change do
    create_table(:sessions) do
      Text :session_type, null: false
      Text :session_id, null: false
      Text :value, null: false
      Bignum :expiry_time_ms, null: false

      unique [:session_type, :session_id]
    end
  end
end
