Sequel.migration do
  change do
    create_table(:partial_state_events) do
      column :room_id, :text, null: false
      column :event_id, :text, null: false, unique: true

      foreign_key [:event_id], :events
      foreign_key [:room_id], :partial_state_rooms
      index :room_id
    end
  end
end
