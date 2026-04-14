Sequel.migration do
  change do
    create_table(:rooms) do
      Text :room_id, primary_key: true
      TrueClass :is_public
      Text :creator
      Text :room_version
      TrueClass :has_auth_chain_index

      index :is_public, name: :public_room_index
    end
  end
end
