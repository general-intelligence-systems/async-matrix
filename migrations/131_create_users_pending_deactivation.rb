Sequel.migration do
  change do
    create_table(:users_pending_deactivation) do
      Text :user_id, null: false
    end
  end
end
