class EventAuthChainToCalculate < Sequel::Model(:event_auth_chain_to_calculate)
  unrestrict_primary_key
  set_primary_key :event_id
end
