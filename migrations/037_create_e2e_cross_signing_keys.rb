Sequel.migration do
  change do
    create_table(:e2e_cross_signing_keys) do
      Text :user_id, null: false
      Text :keytype, null: false
      Text :keydata, null: false
      Bignum :stream_id, null: false

      unique :stream_id
      unique [:user_id, :keytype, :stream_id]
    end
  end
end
