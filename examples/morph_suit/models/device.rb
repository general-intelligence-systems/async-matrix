class Device < Sequel::Model(:devices)
  unrestrict_primary_key
  set_primary_key [:user_id, :device_id]

  many_to_one :user, key: :user_id, primary_key: :name
  one_to_many :device_auth_providers, key: [:user_id, :device_id]
end
