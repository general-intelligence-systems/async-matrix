Sequel.migration do
  change do
    create_table(:current_state_delta_stream) do
      Bignum :stream_id, null: false
      Text :room_id, null: false
      Text :type, null: false
      Text :state_key, null: false
      Text :event_id
      Text :prev_event_id
      Text :instance_name

      index :stream_id, name: :current_state_delta_stream_idx
    end
  end
end
