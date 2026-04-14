Sequel.migration do
  change do
    create_table(:ui_auth_sessions_credentials) do
      foreign_key :session_id, :ui_auth_sessions, type: Text, null: false
      Text :stage_type, null: false
      Text :result, null: false

      unique [:session_id, :stage_type]
    end
  end
end
