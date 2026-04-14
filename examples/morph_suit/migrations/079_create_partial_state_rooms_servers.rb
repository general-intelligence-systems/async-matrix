Sequel.migration do
  change do
    create_table(:partial_state_rooms_servers) do
      column :room_id, :text, null: false
      column :server_name, :text, null: false

      unique [:room_id, :server_name]
      foreign_key [:room_id], :partial_state_rooms
    end
  end
end
