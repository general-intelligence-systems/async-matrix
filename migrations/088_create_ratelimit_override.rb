Sequel.migration do
  change do
    create_table(:ratelimit_override) do
      column :user_id, :text, null: false, unique: true
      column :messages_per_second, :bigint
      column :burst_count, :bigint
    end
  end
end
