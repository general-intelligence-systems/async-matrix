# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:messages) do
      primary_key :id
      String :discord_id, null: false
      String :discord_attachment_id, null: false, default: ""
      String :discord_channel_id, null: false
      String :discord_channel_receiver, null: false, default: ""
      String :discord_sender, null: false
      String :mxid, null: false
      Bignum :timestamp, null: false
      String :discord_thread_id

      unique [:discord_id, :discord_attachment_id, :discord_channel_id, :discord_channel_receiver]
      index :mxid
    end
  end
end
