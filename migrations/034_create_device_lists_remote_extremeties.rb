Sequel.migration do
  change do
    create_table(:device_lists_remote_extremeties) do
      Text :user_id, null: false
      Text :stream_id, null: false

      unique :user_id, name: :device_lists_remote_extremeties_unique_idx
    end
  end
end
