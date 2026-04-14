class RemoteMediaCache < Sequel::Model(:remote_media_cache)
  unrestrict_primary_key

  one_to_many :thumbnails, class: :RemoteMediaCacheThumbnail
end
