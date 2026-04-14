Sequel.migration do
  change do
    create_table(:event_auth) do
      Text :event_id, null: false
      Text :auth_id, null: false
      Text :room_id, null: false

      index :event_id
    end
  end
end
