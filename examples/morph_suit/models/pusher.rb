class Pusher < Sequel::Model(:pushers)
  many_to_one :user, key: :user_name, primary_key: :name
end
