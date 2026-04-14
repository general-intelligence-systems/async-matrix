Sequel.migration do
  change do
    create_table(:remote_media_cache_thumbnails) do
      column :media_origin, :text
      column :media_id, :text
      column :thumbnail_width, :integer
      column :thumbnail_height, :integer
      column :thumbnail_method, :text
      column :thumbnail_type, :text
      column :thumbnail_length, :integer
      column :filesystem_id, :text

      unique [:media_origin, :media_id, :thumbnail_width, :thumbnail_height, :thumbnail_type, :thumbnail_method]
    end
  end
end
