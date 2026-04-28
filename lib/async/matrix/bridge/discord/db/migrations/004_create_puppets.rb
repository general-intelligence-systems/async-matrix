# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:puppets) do
      String :discord_id, primary_key: true
      String :name
      String :avatar_hash
      String :avatar_url
      String :username
      String :global_name
      TrueClass :is_bot, default: false, null: false
      TrueClass :is_webhook, default: false, null: false
      TrueClass :contact_info_set, default: false, null: false
      String :custom_mxid
      String :access_token
    end
  end
end
