Sequel.migration do
  change do
    create_table(:destinations) do
      Text :destination, primary_key: true
      Bignum :retry_last_ts
      Bignum :retry_interval
      Bignum :failure_ts
      Bignum :last_successful_stream_ordering
    end
  end
end
