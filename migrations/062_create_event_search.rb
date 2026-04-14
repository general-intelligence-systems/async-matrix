Sequel.migration do
  change do
    create_table(:event_search) do
      Text :event_id, unique: true
      Text :room_id
      Text :sender
      Text :key
      column :vector, :tsvector
      Bignum :origin_server_ts
      Bignum :stream_ordering

      index :room_id
      index :vector, type: :gin
    end
  end
end
