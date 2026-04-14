Sequel.migration do
  change do
    create_table(:blocked_rooms) do
      Text :room_id, null: false
      Text :user_id, null: false

      unique :room_id, name: :blocked_rooms_idx
    end
  end
end
