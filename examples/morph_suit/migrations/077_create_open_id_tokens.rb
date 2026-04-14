Sequel.migration do
  change do
    create_table(:open_id_tokens) do
      column :token, :text, null: false
      column :ts_valid_until_ms, :bigint, null: false
      column :user_id, :text, null: false

      primary_key [:token]
      index :ts_valid_until_ms
    end
  end
end
