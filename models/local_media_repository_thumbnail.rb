class LocalMediaRepositoryThumbnail < Sequel::Model(:local_media_repository_thumbnails)
  unrestrict_primary_key

  many_to_one :media, class: :LocalMediaRepository, key: :media_id, primary_key: :media_id
end
