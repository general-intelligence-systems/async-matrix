Sequel.migration do
  change do
    create_table(:device_lists_stream) do
      Bignum :stream_id, null: false
      Text :user_id, null: false
      Text :device_id, null: false

      index [:stream_id, :user_id]
      index [:user_id, :device_id]
    end
  end
end
