Sequel.migration do
  change do
    create_table(:push_rules_enable) do
      primary_key :id, type: :bigint
      column :user_name, :text, null: false
      column :rule_id, :text, null: false
      column :enabled, :smallint

      unique [:user_name, :rule_id]
      index :user_name
    end
  end
end
