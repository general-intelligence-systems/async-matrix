Sequel.migration do
  change do
    create_table(:user_ips) do
      Text :user_id, null: false
      Text :access_token, null: false
      Text :device_id
      Text :ip, null: false
      Text :user_agent, null: false
      Bignum :last_seen, null: false

      unique [:user_id, :access_token, :ip]
      index [:user_id, :device_id, :last_seen]
      index [:user_id, :last_seen]
      index :last_seen
    end
  end
end
