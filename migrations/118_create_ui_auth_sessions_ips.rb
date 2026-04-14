Sequel.migration do
  change do
    create_table(:ui_auth_sessions_ips) do
      foreign_key :session_id, :ui_auth_sessions, type: Text, null: false
      Text :ip, null: false
      Text :user_agent, null: false

      unique [:session_id, :ip, :user_agent]
    end
  end
end
