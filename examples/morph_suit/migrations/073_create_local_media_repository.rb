Sequel.migration do
  change do
    create_table(:local_media_repository) do
      column :media_id, :text, unique: true
      column :media_type, :text
      column :media_length, :integer
      column :created_ts, :bigint
      column :upload_name, :text
      column :user_id, :text
      column :quarantined_by, :text
      column :url_cache, :text
      column :last_access_ts, :bigint
      column :safe_from_quarantine, TrueClass, default: false, null: false

      index [:user_id, :created_ts]
    end
  end
end
