Sequel.migration do
  change do
    create_table(:user_stats_current) do
      Text :user_id, primary_key: true
      Bignum :joined_rooms, null: false
      Bignum :completed_delta_stream_id, null: false
    end
  end
end
