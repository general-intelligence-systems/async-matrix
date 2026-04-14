Sequel.migration do
  change do
    create_table(:device_lists_outbound_last_success) do
      Text :destination, null: false
      Text :user_id, null: false
      Bignum :stream_id, null: false

      unique [:destination, :user_id], name: :device_lists_outbound_last_success_unique_idx
    end
  end
end
