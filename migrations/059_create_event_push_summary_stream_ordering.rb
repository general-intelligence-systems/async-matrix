Sequel.migration do
  change do
    create_table(:event_push_summary_stream_ordering) do
      String :lock, size: 1, default: 'X', null: false, unique: true
      Bignum :stream_ordering, null: false
    end
  end
end
