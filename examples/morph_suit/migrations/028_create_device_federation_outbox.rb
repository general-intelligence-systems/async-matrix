Sequel.migration do
  change do
    create_table(:device_federation_outbox) do
      Text :destination, null: false
      Bignum :stream_id, null: false
      Bignum :queued_ts, null: false
      Text :messages_json, null: false
      Text :instance_name

      index [:destination, :stream_id], name: :device_federation_outbox_destination_id
      index :stream_id, name: :device_federation_outbox_id
    end
  end
end
