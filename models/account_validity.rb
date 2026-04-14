class AccountValidity < Sequel::Model(:account_validity)
  unrestrict_primary_key
  set_primary_key :user_id

  many_to_one :user, key: :user_id, primary_key: :name
end
