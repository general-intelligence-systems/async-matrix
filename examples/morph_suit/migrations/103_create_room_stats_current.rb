Sequel.migration do
  change do
    create_table(:room_stats_current) do
      Text :room_id, primary_key: true
      Integer :current_state_events, null: false
      Integer :joined_members, null: false
      Integer :invited_members, null: false
      Integer :left_members, null: false
      Integer :banned_members, null: false
      Integer :local_users_in_room, null: false
      Bignum :completed_delta_stream_id, null: false
      Integer :knocked_members
    end
  end
end
