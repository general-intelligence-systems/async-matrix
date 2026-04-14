Sequel.migration do
  change do
    create_table(:room_retention) do
      Text :room_id, null: false
      Text :event_id, null: false
      Bignum :min_lifetime
      Bignum :max_lifetime

      primary_key [:room_id, :event_id]

      index :max_lifetime
    end
  end
end
