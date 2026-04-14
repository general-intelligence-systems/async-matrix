Sequel.migration do
  change do
    create_table(:event_labels) do
      Text :event_id, null: false
      Text :label, null: false
      Text :room_id, null: false
      Bignum :topological_ordering, null: false

      primary_key [:event_id, :label]
      index [:room_id, :label, :topological_ordering]
    end
  end
end
