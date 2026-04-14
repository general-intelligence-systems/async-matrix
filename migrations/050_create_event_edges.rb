Sequel.migration do
  change do
    create_table(:event_edges) do
      foreign_key :event_id, :events, type: :text, null: false, key: [:event_id]
      Text :prev_event_id, null: false
      Text :room_id
      TrueClass :is_state, default: false, null: false

      unique [:event_id, :prev_event_id]
      index :prev_event_id
    end
  end
end
