class DestinationRoom < Sequel::Model(:destination_rooms)
  unrestrict_primary_key
  set_primary_key [:destination, :room_id]

  many_to_one :destination, key: :destination, primary_key: :destination, class: :Destination
  many_to_one :room, key: :room_id
end
