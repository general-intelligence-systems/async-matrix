Sequel.migration do
  change do
    create_table(:event_auth_chain_links) do
      Bignum :origin_chain_id, null: false
      Bignum :origin_sequence_number, null: false
      Bignum :target_chain_id, null: false
      Bignum :target_sequence_number, null: false

      index [:origin_chain_id, :target_chain_id]
    end
  end
end
