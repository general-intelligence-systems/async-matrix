Sequel.migration do
  change do
    create_table(:application_services_txns) do
      Text :as_id, null: false
      Bignum :txn_id, null: false
      Text :event_ids, null: false

      unique [:as_id, :txn_id]
      index :as_id, name: :application_services_txns_id
    end
  end
end
