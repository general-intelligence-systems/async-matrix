Sequel.migration do
  change do
    create_table(:user_external_ids) do
      Text :auth_provider, null: false
      Text :external_id, null: false
      Text :user_id, null: false

      unique [:auth_provider, :external_id]
      index :user_id
    end
  end
end
