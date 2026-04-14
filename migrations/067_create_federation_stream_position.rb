Sequel.migration do
  change do
    create_table(:federation_stream_position) do
      Text :type, null: false
      Bignum :stream_id, null: false
      Text :instance_name, default: 'master', null: false

      unique [:type, :instance_name]
    end
  end
end
