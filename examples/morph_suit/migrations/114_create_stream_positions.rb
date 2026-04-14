Sequel.migration do
  change do
    create_table(:stream_positions) do
      Text :stream_name, null: false
      Text :instance_name, null: false
      Bignum :stream_id, null: false

      unique [:stream_name, :instance_name]
    end
  end
end
