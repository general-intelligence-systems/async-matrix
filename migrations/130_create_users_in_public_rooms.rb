Sequel.migration do
  change do
    create_table(:users_in_public_rooms) do
      Text :user_id, null: false
      Text :room_id, null: false

      unique [:user_id, :room_id]
      index :room_id
    end
  end
end
