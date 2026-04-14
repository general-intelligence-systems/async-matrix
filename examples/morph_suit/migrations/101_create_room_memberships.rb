Sequel.migration do
  change do
    create_table(:room_memberships) do
      Text :event_id, null: false, unique: true
      Text :user_id, null: false
      Text :sender, null: false
      Text :room_id, null: false
      Text :membership, null: false
      Integer :forgotten, default: 0
      Text :display_name
      Text :avatar_url

      index :room_id
      index :user_id
      index [:user_id, :room_id], where: Sequel.lit('forgotten = 1')
    end
  end
end
