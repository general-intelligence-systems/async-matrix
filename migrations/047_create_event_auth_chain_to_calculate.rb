Sequel.migration do
  change do
    create_table(:event_auth_chain_to_calculate) do
      Text :event_id, null: false, primary_key: true
      Text :room_id, null: false
      Text :type, null: false
      Text :state_key, null: false

      index :room_id
    end
  end
end
