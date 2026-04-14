class UiAuthSessionsCredential < Sequel::Model(:ui_auth_sessions_credentials)
  unrestrict_primary_key

  many_to_one :ui_auth_session
end
