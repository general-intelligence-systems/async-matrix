class Destination < Sequel::Model(:destinations)
  unrestrict_primary_key
  set_primary_key :destination

  one_to_many :destination_rooms, key: :destination
end
