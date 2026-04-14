class AccountData < Sequel::Model(:account_data)
  unrestrict_primary_key
  set_primary_key [:user_id, :account_data_type]

  many_to_one :user, key: :user_id, primary_key: :name
end
