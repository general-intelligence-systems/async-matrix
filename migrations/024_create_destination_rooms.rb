Sequel.migration do
  change do
    create_table(:destination_rooms) do
      Text :destination, null: false
      Text :room_id, null: false
      Bignum :stream_ordering, null: false

      primary_key [:destination, :room_id]

      index :room_id, name: :destination_rooms_room_id
    end
  end
end
