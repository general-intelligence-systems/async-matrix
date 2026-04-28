# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:portals) do
      String :discord_id, null: false
      String :receiver, null: false, default: ""
      String :mxid, unique: true
      String :discord_guild_id
      String :name
      String :topic
      String :avatar_hash
      String :avatar_url
      TrueClass :encrypted, default: false, null: false
      Integer :channel_type, default: 0, null: false
      String :relay_webhook_id
      String :relay_webhook_secret

      primary_key [:discord_id, :receiver]
      foreign_key [:discord_guild_id], :guilds, key: :discord_id
    end
  end
end
