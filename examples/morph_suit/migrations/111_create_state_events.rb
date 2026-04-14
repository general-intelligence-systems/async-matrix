Sequel.migration do
  change do
    create_table(:state_events) do
      Text :event_id, null: false, unique: true
      Text :room_id, null: false
      Text :type, null: false
      Text :state_key, null: false
      Text :prev_state
    end
  end
end
