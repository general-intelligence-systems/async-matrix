Sequel.migration do
  change do
    create_table(:insertion_events) do
      column :event_id, :text, null: false, unique: true
      column :room_id, :text, null: false
      column :next_batch_id, :text, null: false

      index :next_batch_id
    end
  end
end
