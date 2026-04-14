Sequel.migration do
  change do
    create_table(:event_txn_id) do
      foreign_key :event_id, :events, type: :text, null: false, unique: true, key: [:event_id], on_delete: :cascade
      Text :room_id, null: false
      Text :user_id, null: false
      foreign_key :token_id, :access_tokens, type: :Bignum, null: false, on_delete: :cascade
      Text :txn_id, null: false
      Bignum :inserted_ts, null: false

      unique [:room_id, :user_id, :token_id, :txn_id]
      index :inserted_ts
    end
  end
end
