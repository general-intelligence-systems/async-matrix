Sequel.migration do
  change do
    create_table(:ex_outlier_stream) do
      Bignum :event_stream_ordering, null: false, primary_key: true
      Text :event_id, null: false
      Bignum :state_group, null: false
      Text :instance_name
    end
  end
end
