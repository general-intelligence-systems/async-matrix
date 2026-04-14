Sequel.migration do
  change do
    create_table(:event_to_state_groups) do
      Text :event_id, null: false, unique: true
      Bignum :state_group, null: false

      index :state_group
    end
  end
end
