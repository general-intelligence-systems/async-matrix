class AppserviceStreamPosition < Sequel::Model(:appservice_stream_position)
  unrestrict_primary_key
  set_primary_key :lock
end
