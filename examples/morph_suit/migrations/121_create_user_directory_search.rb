Sequel.migration do
  change do
    create_table(:user_directory_search) do
      Text :user_id, null: false, unique: true
      column :vector, 'tsvector'

      index :vector, type: :gin
    end
  end
end
