Sequel.migration do
  change do
    create_table(:device_federation_inbox) do
      Text :origin, null: false
      Text :message_id, null: false
      Bignum :received_ts, null: false
      Text :instance_name

      index [:origin, :message_id], name: :device_federation_inbox_sender_id
    end
  end
end
