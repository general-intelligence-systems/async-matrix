Sequel.migration do
  change do
    create_table(:event_auth_chains) do
      Text :event_id, null: false, primary_key: true
      Bignum :chain_id, null: false
      Bignum :sequence_number, null: false

      unique [:chain_id, :sequence_number]
    end
  end
end
