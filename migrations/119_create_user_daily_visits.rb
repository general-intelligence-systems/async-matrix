Sequel.migration do
  change do
    create_table(:user_daily_visits) do
      Text :user_id, null: false
      Text :device_id
      Bignum :timestamp, null: false
      Text :user_agent

      index :timestamp
      index [:user_id, :timestamp]
    end
  end
end
