Sequel.migration do
  change do
    create_table(:worker_locks) do
      Text :lock_name, null: false
      Text :lock_key, null: false
      Text :instance_name, null: false
      Text :token, null: false
      Bignum :last_renewed_ts, null: false

      unique [:lock_name, :lock_key]
    end
  end
end
