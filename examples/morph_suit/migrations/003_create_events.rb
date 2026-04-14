Sequel.migration do
  change do
    create_table(:events) do
      Bignum :topological_ordering, null: false
      Text :event_id, null: false, unique: true
      Text :type, null: false
      Text :room_id, null: false
      Text :content
      Text :unrecognized_keys
      TrueClass :processed, null: false
      TrueClass :outlier, null: false
      Bignum :depth, default: 0, null: false
      Bignum :origin_server_ts
      Bignum :received_ts
      Text :sender
      TrueClass :contains_url
      Text :instance_name
      Bignum :stream_ordering, unique: true
      Text :state_key
      Text :rejection_reason

      index [:room_id, :topological_ordering, :stream_ordering], name: :events_order_room
      index [:room_id, :stream_ordering], name: :events_room_stream
      index [:origin_server_ts, :stream_ordering], name: :events_ts
    end
  end
end
