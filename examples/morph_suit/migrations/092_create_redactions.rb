Sequel.migration do
  change do
    create_table(:redactions) do
      column :event_id, :text, null: false, unique: true
      column :redacts, :text, null: false
      column :have_censored, TrueClass, default: false, null: false
      column :received_ts, :bigint

      index :redacts
    end
  end
end
