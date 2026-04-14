Sequel.migration do
  change do
    create_table(:push_rules_stream) do
      column :stream_id, :bigint, null: false
      column :event_stream_ordering, :bigint, null: false
      column :user_id, :text, null: false
      column :rule_id, :text, null: false
      column :op, :text, null: false
      column :priority_class, :smallint
      column :priority, :integer
      column :conditions, :text
      column :actions, :text

      index :stream_id
      index [:user_id, :stream_id]
    end
  end
end
