Sequel.migration do
  change do
    create_table(:receipts_linearized) do
      column :stream_id, :bigint, null: false
      column :room_id, :text, null: false
      column :receipt_type, :text, null: false
      column :user_id, :text, null: false
      column :event_id, :text, null: false
      column :data, :text, null: false
      column :instance_name, :text
      column :event_stream_ordering, :bigint
      column :thread_id, :text

      unique [:room_id, :receipt_type, :user_id]
      unique [:room_id, :receipt_type, :user_id, :thread_id]
      index :stream_id
      index [:room_id, :stream_id]
      index :user_id
    end
  end
end
