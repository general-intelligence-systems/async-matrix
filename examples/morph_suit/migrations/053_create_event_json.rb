Sequel.migration do
  change do
    create_table(:event_json) do
      Text :event_id, null: false, unique: true
      Text :room_id, null: false
      Text :internal_metadata, null: false
      Text :json, null: false
      Integer :format_version
    end
  end
end
