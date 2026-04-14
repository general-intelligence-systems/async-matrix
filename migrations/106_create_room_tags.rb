Sequel.migration do
  change do
    create_table(:room_tags) do
      Text :user_id, null: false
      Text :room_id, null: false
      Text :tag, null: false
      Text :content, null: false

      unique [:user_id, :room_id, :tag]
    end
  end
end
