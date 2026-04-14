Sequel.migration do
  change do
    create_table(:room_alias_servers) do
      column :room_alias, :text, null: false
      column :server, :text, null: false

      index :room_alias
    end
  end
end
