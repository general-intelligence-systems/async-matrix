class EventAuthChain < Sequel::Model(:event_auth_chains)
  unrestrict_primary_key
  set_primary_key :event_id
end
