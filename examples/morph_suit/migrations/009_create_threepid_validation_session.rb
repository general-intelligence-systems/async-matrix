Sequel.migration do
  change do
    create_table(:threepid_validation_session) do
      Text :session_id, primary_key: true
      Text :medium, null: false
      Text :address, null: false
      Text :client_secret, null: false
      Bignum :last_send_attempt, null: false
      Bignum :validated_at
    end
  end
end
