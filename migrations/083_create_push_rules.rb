Sequel.migration do
  change do
    create_table(:push_rules) do
      primary_key :id, type: :bigint
      column :user_name, :text, null: false
      column :rule_id, :text, null: false
      column :priority_class, :smallint, null: false
      column :priority, :integer, default: 0, null: false
      column :conditions, :text, null: false
      column :actions, :text, null: false

      unique [:user_name, :rule_id]
      index :user_name
    end
  end
end
