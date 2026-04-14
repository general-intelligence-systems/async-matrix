class LocalMediaRepository < Sequel::Model(:local_media_repository)
  unrestrict_primary_key

  one_to_many :thumbnails, class: :LocalMediaRepositoryThumbnail
end
