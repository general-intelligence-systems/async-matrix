Sequel.migration do
  change do
    create_table(:devices) do
      Text :user_id, null: false
      Text :device_id, null: false
      Text :display_name
      Bignum :last_seen
      Text :ip
      Text :user_agent
      TrueClass :hidden, default: false

      unique [:user_id, :device_id]
    end
  end
end
