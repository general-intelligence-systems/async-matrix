Sequel.migration do
  change do
    create_table(:access_tokens) do
      primary_key :id, type: :Bignum
      Text :user_id, null: false
      Text :device_id
      Text :token, null: false, unique: true
      Bignum :valid_until_ms
      Text :puppets_user_id
      Bignum :last_validated
      Bignum :refresh_token_id
      TrueClass :used

      index [:user_id, :device_id], name: :access_tokens_device_id
    end
  end
end
