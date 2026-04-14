Sequel.migration do
  change do
    create_table(:room_aliases) do
      column :room_alias, :text, null: false, unique: true
      column :room_id, :text, null: false
      column :creator, :text

      index :room_id
    end
  end
end
