Sequel.migration do
  change do
    create_table(:room_depth) do
      column :room_id, :text, null: false, unique: true
      column :min_depth, :bigint
    end
  end
end
