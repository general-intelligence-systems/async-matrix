Sequel.migration do
  change do
    create_table(:ignored_users) do
      column :ignorer_user_id, :text, null: false
      column :ignored_user_id, :text, null: false

      unique [:ignorer_user_id, :ignored_user_id]
      index :ignored_user_id
    end
  end
end
