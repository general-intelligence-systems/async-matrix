class ThreepidValidationSession < Sequel::Model(:threepid_validation_session)
  unrestrict_primary_key
  set_primary_key :session_id
end
