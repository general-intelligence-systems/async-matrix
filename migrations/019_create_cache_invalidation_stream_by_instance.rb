Sequel.migration do
  change do
    create_table(:cache_invalidation_stream_by_instance) do
      Bignum :stream_id, null: false
      Text :instance_name, null: false
      Text :cache_func, null: false
      column :keys, 'text[]'
      Bignum :invalidation_ts

      unique :stream_id, name: :cache_invalidation_stream_by_instance_id
      index [:instance_name, :stream_id], name: :instance_index
    end
  end
end
