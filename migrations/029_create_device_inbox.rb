Sequel.migration do
  change do
    create_table(:device_inbox) do
      Text :user_id, null: false
      Text :device_id, null: false
      Bignum :stream_id, null: false
      Text :message_json, null: false
      Text :instance_name

      index [:stream_id, :user_id], name: :device_inbox_stream_id_user_id
      index [:user_id, :device_id, :stream_id], name: :device_inbox_user_stream_id
    end
  end
end
