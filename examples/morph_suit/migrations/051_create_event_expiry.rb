Sequel.migration do
  change do
    create_table(:event_expiry) do
      Text :event_id, null: false, primary_key: true
      Bignum :expiry_ts, null: false

      index :expiry_ts
    end
  end
end
