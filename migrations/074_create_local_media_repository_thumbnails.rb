Sequel.migration do
  change do
    create_table(:local_media_repository_thumbnails) do
      column :media_id, :text
      column :thumbnail_width, :integer
      column :thumbnail_height, :integer
      column :thumbnail_type, :text
      column :thumbnail_method, :text
      column :thumbnail_length, :integer

      unique [:media_id, :thumbnail_width, :thumbnail_height, :thumbnail_type, :thumbnail_method]
      index :media_id
    end
  end
end
