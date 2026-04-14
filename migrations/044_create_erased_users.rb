Sequel.migration do
  change do
    create_table(:erased_users) do
      Text :user_id, null: false

      unique :user_id
    end
  end
end
