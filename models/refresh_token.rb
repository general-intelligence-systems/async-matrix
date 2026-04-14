class RefreshToken < Sequel::Model(:refresh_tokens)
  many_to_one :user, key: :user_id, primary_key: :name
  many_to_one :next_token, class: self, key: :next_token_id
  one_to_one :previous_token, class: self, key: :next_token_id
end
