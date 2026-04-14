Sequel.migration do
  change do
    create_table(:rejections) do
      column :event_id, :text, null: false, unique: true
      column :reason, :text, null: false
      column :last_check, :text, null: false
    end
  end
end
