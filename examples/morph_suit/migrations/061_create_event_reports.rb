Sequel.migration do
  change do
    create_table(:event_reports) do
      primary_key :id, type: :Bignum
      Bignum :received_ts, null: false
      Text :room_id, null: false
      Text :event_id, null: false
      Text :user_id, null: false
      Text :reason
      Text :content
    end
  end
end
