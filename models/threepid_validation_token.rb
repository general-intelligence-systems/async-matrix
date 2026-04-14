class ThreepidValidationToken < Sequel::Model(:threepid_validation_token)
  unrestrict_primary_key
  set_primary_key :token

  many_to_one :session, class: :ThreepidValidationSession, key: :session_id
end
