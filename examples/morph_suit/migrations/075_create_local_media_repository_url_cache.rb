Sequel.migration do
  change do
    create_table(:local_media_repository_url_cache) do
      column :url, :text
      column :response_code, :integer
      column :etag, :text
      column :expires_ts, :bigint
      column :og, :text
      column :media_id, :text
      column :download_ts, :bigint

      index [:url, :download_ts]
      index :expires_ts
      index :media_id
    end
  end
end
