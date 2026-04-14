Sequel.migration do
  change do
    create_table(:partial_state_rooms) do
      Text :room_id, primary_key: true
    end
  end
end
