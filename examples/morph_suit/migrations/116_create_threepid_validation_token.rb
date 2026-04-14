Sequel.migration do
  change do
    create_table(:threepid_validation_token) do
      Text :token, primary_key: true
      Text :session_id, null: false
      Text :next_link
      Bignum :expires, null: false

      index :session_id
    end
  end
end
