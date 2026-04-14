Sequel.migration do
  change do
    create_table(:e2e_room_keys) do
      Text :user_id, null: false
      Text :room_id, null: false
      Text :session_id, null: false
      Bignum :version, null: false
      Integer :first_message_index
      Integer :forwarded_count
      TrueClass :is_verified
      Text :session_data, null: false

      unique [:user_id, :version, :room_id, :session_id]
    end
  end
end
