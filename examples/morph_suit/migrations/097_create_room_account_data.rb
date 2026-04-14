Sequel.migration do
  change do
    create_table(:room_account_data) do
      column :user_id, :text, null: false
      column :room_id, :text, null: false
      column :account_data_type, :text, null: false
      column :stream_id, :bigint, null: false
      column :content, :text, null: false
      column :instance_name, :text

      unique [:user_id, :room_id, :account_data_type]
      index [:user_id, :stream_id]
    end
  end
end
