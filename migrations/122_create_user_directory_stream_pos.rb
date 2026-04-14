Sequel.migration do
  change do
    create_table(:user_directory_stream_pos) do
      String :lock, size: 1, default: 'X', null: false, unique: true
      Bignum :stream_id
    end
  end
end
