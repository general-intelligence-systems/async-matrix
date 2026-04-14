Sequel.migration do
  change do
    create_table(:remote_media_cache) do
      column :media_origin, :text
      column :media_id, :text
      column :media_type, :text
      column :created_ts, :bigint
      column :upload_name, :text
      column :media_length, :integer
      column :filesystem_id, :text
      column :last_access_ts, :bigint
      column :quarantined_by, :text

      unique [:media_origin, :media_id]
    end
  end
end
