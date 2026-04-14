Sequel.migration do
  change do
    create_table(:event_push_actions) do
      Text :room_id, null: false
      Text :event_id, null: false
      Text :user_id, null: false
      String :profile_tag, size: 32
      Text :actions, null: false
      Bignum :topological_ordering
      Bignum :stream_ordering
      Smallint :notif
      Smallint :highlight
      Smallint :unread
      Text :thread_id

      unique [:room_id, :event_id, :user_id, :profile_tag]
      index [:room_id, :user_id]
      index [:stream_ordering, :user_id]
      index [:user_id, :room_id, :topological_ordering, :stream_ordering]
      index [:user_id, :stream_ordering]
    end
  end
end
