class Profile < Sequel::Model(:profiles)
  unrestrict_primary_key

  many_to_one :user, key: :user_id, primary_key: :name
end
