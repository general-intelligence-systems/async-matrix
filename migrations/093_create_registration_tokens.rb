Sequel.migration do
  change do
    create_table(:registration_tokens) do
      column :token, :text, null: false, unique: true
      column :uses_allowed, :integer
      column :pending, :integer, null: false
      column :completed, :integer, null: false
      column :expiry_time, :bigint
    end
  end
end
