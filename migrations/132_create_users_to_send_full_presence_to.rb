Sequel.migration do
  change do
    create_table(:users_to_send_full_presence_to) do
      Text :user_id, primary_key: true
      Bignum :presence_stream_id

      foreign_key [:user_id], :users, key: [:name]
    end
  end
end
