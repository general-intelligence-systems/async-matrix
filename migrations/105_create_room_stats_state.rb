Sequel.migration do
  change do
    create_table(:room_stats_state) do
      Text :room_id, null: false, unique: true
      Text :name
      Text :canonical_alias
      Text :join_rules
      Text :history_visibility
      Text :encryption
      Text :avatar
      Text :guest_access
      TrueClass :is_federatable
      Text :topic
      Text :room_type
    end
  end
end
