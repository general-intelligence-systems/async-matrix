Sequel.migration do
  change do
    create_table(:federation_inbound_events_staging) do
      Text :origin, null: false
      Text :room_id, null: false
      Text :event_id, null: false
      Bignum :received_ts, null: false
      Text :event_json, null: false
      Text :internal_metadata, null: false

      unique [:origin, :event_id]
      index [:room_id, :received_ts]
    end
  end
end
