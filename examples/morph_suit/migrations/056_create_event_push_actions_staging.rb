Sequel.migration do
  change do
    create_table(:event_push_actions_staging) do
      Text :event_id, null: false
      Text :user_id, null: false
      Text :actions, null: false
      Smallint :notif, null: false
      Smallint :highlight, null: false
      Smallint :unread
      Text :thread_id

      index :event_id
    end
  end
end
