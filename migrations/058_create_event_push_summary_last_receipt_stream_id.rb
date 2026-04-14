Sequel.migration do
  change do
    create_table(:event_push_summary_last_receipt_stream_id) do
      String :lock, size: 1, default: 'X', null: false, unique: true
      Bignum :stream_id, null: false
    end
  end
end
