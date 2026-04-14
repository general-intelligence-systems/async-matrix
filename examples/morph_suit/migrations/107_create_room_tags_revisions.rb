Sequel.migration do
  change do
    create_table(:room_tags_revisions) do
      Text :user_id, null: false
      Text :room_id, null: false
      Bignum :stream_id, null: false
      Text :instance_name

      unique [:user_id, :room_id]
    end
  end
end
