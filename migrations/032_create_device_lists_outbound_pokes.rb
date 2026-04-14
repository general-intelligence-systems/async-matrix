Sequel.migration do
  change do
    create_table(:device_lists_outbound_pokes) do
      Text :destination, null: false
      Bignum :stream_id, null: false
      Text :user_id, null: false
      Text :device_id, null: false
      TrueClass :sent, null: false
      Bignum :ts, null: false
      Text :opentracing_context

      index [:destination, :stream_id], name: :pokes_id
      index :stream_id, name: :pokes_stream
      index [:destination, :user_id], name: :pokes_user
    end
  end
end
