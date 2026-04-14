Sequel.migration do
  change do
    create_table(:event_relations) do
      Text :event_id, null: false, unique: true
      Text :relates_to_id, null: false
      Text :relation_type, null: false
      Text :aggregation_key

      index [:relates_to_id, :relation_type, :aggregation_key]
    end
  end
end
