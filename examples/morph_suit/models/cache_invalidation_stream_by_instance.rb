class CacheInvalidationStreamByInstance < Sequel::Model(:cache_invalidation_stream_by_instance)
  unrestrict_primary_key
  set_primary_key :stream_id
end
