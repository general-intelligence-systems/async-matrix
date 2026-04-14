Sequel.migration do
  change do
    create_table(:pushers) do
      primary_key :id, type: :bigint
      column :user_name, :text, null: false
      column :access_token, :bigint
      column :profile_tag, :text, null: false
      column :kind, :text, null: false
      column :app_id, :text, null: false
      column :app_display_name, :text, null: false
      column :device_display_name, :text, null: false
      column :pushkey, :text, null: false
      column :ts, :bigint, null: false
      column :lang, :text
      column :data, :text
      column :last_stream_ordering, :bigint
      column :last_success, :bigint
      column :failing_since, :bigint

      unique [:app_id, :pushkey, :user_name]
    end
  end
end
