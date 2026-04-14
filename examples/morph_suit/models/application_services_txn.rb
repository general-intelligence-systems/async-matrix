class ApplicationServicesTxn < Sequel::Model(:application_services_txns)
  unrestrict_primary_key
  set_primary_key [:as_id, :txn_id]
end
