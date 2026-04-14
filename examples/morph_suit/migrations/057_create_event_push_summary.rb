Sequel.migration do
  change do
    create_table(:event_push_summary) do
      Text :user_id, null: false
      Text :room_id, null: false
      Bignum :notif_count, null: false
      Bignum :stream_ordering, null: false
      Bignum :unread_count
      Bignum :last_receipt_stream_ordering
      Text :thread_id

      unique [:user_id, :room_id]
      unique [:user_id, :room_id, :thread_id]
    end
  end
end
