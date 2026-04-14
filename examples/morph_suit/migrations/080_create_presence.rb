Sequel.migration do
  change do
    create_table(:presence) do
      column :user_id, :text, null: false, unique: true
      column :state, 'varchar(20)'
      column :status_msg, :text
      column :mtime, :bigint
    end
  end
end
