Sequel.migration do
  change do
    create_table(:presence_stream) do
      column :stream_id, :bigint
      column :user_id, :text
      column :state, :text
      column :last_active_ts, :bigint
      column :last_federation_update_ts, :bigint
      column :last_user_sync_ts, :bigint
      column :status_msg, :text
      column :currently_active, TrueClass
      column :instance_name, :text

      index [:stream_id, :user_id]
      index :user_id
    end
  end
end
