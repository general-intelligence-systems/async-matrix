Sequel.migration do
  change do
    create_table(:deleted_pushers) do
      Bignum :stream_id, null: false
      Text :app_id, null: false
      Text :pushkey, null: false
      Text :user_id, null: false

      index :stream_id, name: :deleted_pushers_stream_id
    end
  end
end
