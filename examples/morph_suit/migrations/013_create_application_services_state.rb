Sequel.migration do
  change do
    create_table(:application_services_state) do
      Text :as_id, primary_key: true
      String :state, size: 5
      Bignum :read_receipt_stream_id
      Bignum :presence_stream_id
      Bignum :to_device_stream_id
      Bignum :device_list_stream_id
    end
  end
end
