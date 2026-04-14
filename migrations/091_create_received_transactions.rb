Sequel.migration do
  change do
    create_table(:received_transactions) do
      column :transaction_id, :text
      column :origin, :text
      column :ts, :bigint
      column :response_code, :integer
      column :response_json, File
      column :has_been_referenced, :smallint, default: 0

      unique [:transaction_id, :origin]
      index :ts
    end
  end
end
