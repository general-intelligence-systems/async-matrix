Sequel.migration do
  change do
    create_table(:refresh_tokens) do
      primary_key :id, type: :Bignum
      Text :user_id, null: false
      Text :device_id, null: false
      Text :token, null: false, unique: true
      Bignum :next_token_id
      Bignum :expiry_ts
      Bignum :ultimate_session_expiry_ts

      index :next_token_id, name: :refresh_tokens_next_token_id, where: Sequel.lit('next_token_id IS NOT NULL')
    end
  end
end
