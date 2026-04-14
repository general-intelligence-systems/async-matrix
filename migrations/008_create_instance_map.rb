Sequel.migration do
  change do
    create_table(:instance_map) do
      primary_key :instance_id, type: Integer
      Text :instance_name, null: false, unique: true
    end
  end
end
