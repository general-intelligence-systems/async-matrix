Sequel.migration do
  change do
    create_table(:users) do
      Text :name, unique: true
      Text :password_hash
      Bignum :creation_ts
      Smallint :admin, default: 0, null: false
      Bignum :upgrade_ts
      Smallint :is_guest, default: 0, null: false
      Text :appservice_id
      Text :consent_version
      Text :consent_server_notice_sent
      Text :user_type
      Smallint :deactivated, default: 0, null: false
      TrueClass :shadow_banned
      Bignum :consent_ts

      index :creation_ts, name: :users_creation_ts
    end
  end
end
