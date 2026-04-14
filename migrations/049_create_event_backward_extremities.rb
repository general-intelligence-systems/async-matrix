Sequel.migration do
  change do
    create_table(:event_backward_extremities) do
      Text :event_id, null: false
      Text :room_id, null: false

      unique [:event_id, :room_id]
      index :event_id
      index :room_id
    end
  end
end
