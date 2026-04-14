Sequel.migration do
  change do
    create_table(:appservice_room_list) do
      Text :appservice_id, null: false
      Text :network_id, null: false
      Text :room_id, null: false

      unique [:appservice_id, :network_id, :room_id], name: :appservice_room_list_idx
    end
  end
end
