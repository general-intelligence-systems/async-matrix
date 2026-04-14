class UserThreepid < Sequel::Model(:user_threepids)
  unrestrict_primary_key

  many_to_one :user, key: :user_id, primary_key: :name
end
