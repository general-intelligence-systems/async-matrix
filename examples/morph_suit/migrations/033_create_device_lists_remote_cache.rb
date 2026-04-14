Sequel.migration do
  change do
    create_table(:device_lists_remote_cache) do
      Text :user_id, null: false
      Text :device_id, null: false
      Text :content, null: false

      unique [:user_id, :device_id], name: :device_lists_remote_cache_unique_id
    end
  end
end
