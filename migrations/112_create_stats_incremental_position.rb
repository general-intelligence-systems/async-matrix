Sequel.migration do
  change do
    create_table(:stats_incremental_position) do
      String :lock, size: 1, default: 'X', null: false, unique: true
      Bignum :stream_id, null: false
    end
  end
end
