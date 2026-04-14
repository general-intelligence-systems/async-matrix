class RoomAlias < Sequel::Model(:room_aliases)
  unrestrict_primary_key

  many_to_one :room
end
