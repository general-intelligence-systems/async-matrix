Sequel.migration do
  change do
    create_table(:monthly_active_users) do
      column :user_id, :text, null: false, unique: true
      column :timestamp, :bigint, null: false

      index :timestamp
    end
  end
end
