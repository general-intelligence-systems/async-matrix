Sequel.migration do
  change do
    create_table(:account_data) do
      Text :user_id, null: false
      Text :account_data_type, null: false
      Bignum :stream_id, null: false
      Text :content, null: false
      Text :instance_name

      unique [:user_id, :account_data_type]
      index [:user_id, :stream_id], name: :account_data_stream_id
    end
  end
end
