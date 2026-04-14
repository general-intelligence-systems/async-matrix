Sequel.migration do
  change do
    create_table(:ui_auth_sessions) do
      Text :session_id, null: false, unique: true
      Bignum :creation_time, null: false
      Text :serverdict, null: false
      Text :clientdict, null: false
      Text :uri, null: false
      Text :method, null: false
      Text :description, null: false
    end
  end
end
