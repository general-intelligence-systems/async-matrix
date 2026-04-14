Sequel.migration do
  change do
    create_table(:account_validity) do
      Text :user_id, primary_key: true
      Bignum :expiration_ts_ms, null: false
      TrueClass :email_sent, null: false
      Text :renewal_token
      Bignum :token_used_ts_ms
    end
  end
end
