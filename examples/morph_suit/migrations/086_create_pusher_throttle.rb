Sequel.migration do
  change do
    create_table(:pusher_throttle) do
      column :pusher, :bigint, null: false
      column :room_id, :text, null: false
      column :last_sent_ts, :bigint
      column :throttle_ms, :bigint

      primary_key [:pusher, :room_id]
    end
  end
end
