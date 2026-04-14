Sequel.migration do
  change do
    create_table(:user_directory) do
      Text :user_id, null: false, unique: true
      Text :room_id
      Text :display_name
      Text :avatar_url

      index :room_id
    end
  end
end
