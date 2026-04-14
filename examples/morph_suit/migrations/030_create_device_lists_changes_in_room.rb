Sequel.migration do
  change do
    create_table(:device_lists_changes_in_room) do
      Text :user_id, null: false
      Text :device_id, null: false
      Text :room_id, null: false
      Bignum :stream_id, null: false
      TrueClass :converted_to_destinations, null: false
      Text :opentracing_context

      unique [:stream_id, :room_id], name: :device_lists_changes_in_stream_id
    end
  end
end
