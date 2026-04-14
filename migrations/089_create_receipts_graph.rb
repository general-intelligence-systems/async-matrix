Sequel.migration do
  change do
    create_table(:receipts_graph) do
      column :room_id, :text, null: false
      column :receipt_type, :text, null: false
      column :user_id, :text, null: false
      column :event_ids, :text, null: false
      column :data, :text, null: false
      column :thread_id, :text

      unique [:room_id, :receipt_type, :user_id]
      unique [:room_id, :receipt_type, :user_id, :thread_id]
    end
  end
end
