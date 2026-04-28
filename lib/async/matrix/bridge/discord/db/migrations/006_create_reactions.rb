# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:reactions) do
      primary_key :id
      String :discord_message_id, null: false
      String :discord_sender, null: false
      String :discord_emoji_name, null: false
      String :mxid, null: false
      String :discord_channel_id, null: false
      String :discord_channel_receiver, null: false, default: ""
      String :discord_thread_id

      unique [:discord_message_id, :discord_sender, :discord_emoji_name]
      index :mxid
    end
  end
end
