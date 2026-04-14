Sequel.migration do
  change do
    create_table(:insertion_event_extremities) do
      column :event_id, :text, null: false, unique: true
      column :room_id, :text, null: false

      index :room_id
    end
  end
end
