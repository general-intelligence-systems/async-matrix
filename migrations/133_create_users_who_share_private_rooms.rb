Sequel.migration do
  change do
    create_table(:users_who_share_private_rooms) do
      Text :user_id, null: false
      Text :other_user_id, null: false
      Text :room_id, null: false

      unique [:user_id, :other_user_id, :room_id]
      index :other_user_id
      index :room_id
    end
  end
end
