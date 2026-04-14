Sequel.migration do
  change do
    create_table(:device_lists_remote_resync) do
      Text :user_id, null: false
      Bignum :added_ts, null: false

      unique :user_id
      index :added_ts
    end
  end
end
