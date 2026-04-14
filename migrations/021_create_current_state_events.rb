Sequel.migration do
  change do
    create_table(:current_state_events) do
      Text :event_id, null: false, unique: true
      Text :room_id, null: false
      Text :type, null: false
      Text :state_key, null: false
      Text :membership

      unique [:room_id, :type, :state_key]
      index :state_key, name: :current_state_events_member_index, where: Sequel.lit("type = 'm.room.member'")
    end
  end
end
