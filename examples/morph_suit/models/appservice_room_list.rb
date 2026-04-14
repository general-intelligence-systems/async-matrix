class AppserviceRoomList < Sequel::Model(:appservice_room_list)
  unrestrict_primary_key
  set_primary_key [:appservice_id, :network_id, :room_id]
end
