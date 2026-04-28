# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:users) do
      String :mxid, primary_key: true
      String :discord_id, unique: true
      String :discord_token
      String :management_room
      String :space_room
      String :dm_space_room
    end
  end
end
