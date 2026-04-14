Sequel.migration do
  change do
    create_table(:user_threepid_id_server) do
      Text :user_id, null: false
      Text :medium, null: false
      Text :address, null: false
      Text :id_server, null: false

      unique [:user_id, :medium, :address, :id_server]
    end
  end
end
