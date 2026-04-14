Sequel.migration do
  change do
    create_table(:room_stats_earliest_token) do
      Text :room_id, null: false, unique: true
      Bignum :token, null: false
    end
  end
end
