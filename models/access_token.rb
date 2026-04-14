class AccessToken < Sequel::Model(:access_tokens)
  many_to_one :user, key: :user_id, primary_key: :name
  many_to_one :refresh_token, key: :refresh_token_id
end
