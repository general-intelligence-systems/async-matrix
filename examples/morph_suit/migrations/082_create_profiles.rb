Sequel.migration do
  change do
    create_table(:profiles) do
      column :user_id, :text, null: false, unique: true
      column :displayname, :text
      column :avatar_url, :text
    end
  end
end
