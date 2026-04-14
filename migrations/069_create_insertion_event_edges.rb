Sequel.migration do
  change do
    create_table(:insertion_event_edges) do
      column :event_id, :text, null: false
      column :room_id, :text, null: false
      column :insertion_prev_event_id, :text, null: false

      index :event_id
      index :insertion_prev_event_id
      index :room_id
    end
  end
end
