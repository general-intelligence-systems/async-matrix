class ApplicationServicesState < Sequel::Model(:application_services_state)
  unrestrict_primary_key
  set_primary_key :as_id
end
