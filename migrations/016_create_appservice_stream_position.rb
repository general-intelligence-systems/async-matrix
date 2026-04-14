Sequel.migration do
  change do
    create_table(:appservice_stream_position) do
      String :lock, size: 1, default: 'X', null: false, unique: true
      Bignum :stream_ordering
    end
  end
end
