# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:guilds) do
      String :discord_id, primary_key: true
      String :mxid, unique: true
      String :name
      String :avatar_hash
      String :avatar_url
      Integer :bridging_mode, default: 0, null: false
    end
  end
end
