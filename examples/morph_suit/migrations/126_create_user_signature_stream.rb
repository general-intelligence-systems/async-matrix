Sequel.migration do
  change do
    create_table(:user_signature_stream) do
      Bignum :stream_id, null: false, unique: true
      Text :from_user_id, null: false
      Text :user_ids, null: false
    end
  end
end
