Sequel.migration do
  change do
    create_table(:e2e_room_keys_versions) do
      Text :user_id, null: false
      Bignum :version, null: false
      Text :algorithm, null: false
      Text :auth_data, null: false
      Smallint :deleted, default: 0, null: false
      Bignum :etag

      unique [:user_id, :version]
    end
  end
end
