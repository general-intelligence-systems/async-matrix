Sequel.migration do
  change do
    create_table(:stream_ordering_to_exterm) do
      Bignum :stream_ordering, null: false
      Text :room_id, null: false
      Text :event_id, null: false

      index :stream_ordering
      index [:room_id, :stream_ordering]
    end
  end
end
