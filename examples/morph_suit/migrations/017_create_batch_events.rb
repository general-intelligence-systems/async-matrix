Sequel.migration do
  change do
    create_table(:batch_events) do
      Text :event_id, null: false
      Text :room_id, null: false
      Text :batch_id, null: false

      unique :event_id, name: :chunk_events_event_id
      index :batch_id, name: :batch_events_batch_id
    end
  end
end
