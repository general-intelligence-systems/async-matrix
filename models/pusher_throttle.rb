class PusherThrottle < Sequel::Model(:pusher_throttle)
  unrestrict_primary_key
  set_primary_key [:pusher, :room_id]
end
