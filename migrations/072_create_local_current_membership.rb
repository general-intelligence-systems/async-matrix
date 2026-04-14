Sequel.migration do
  change do
    create_table(:local_current_membership) do
      column :room_id, :text, null: false
      column :user_id, :text, null: false
      column :event_id, :text, null: false
      column :membership, :text, null: false

      unique [:user_id, :room_id]
      index :room_id
    end
  end
end
