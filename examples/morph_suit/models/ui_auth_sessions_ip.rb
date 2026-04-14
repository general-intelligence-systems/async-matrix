class UiAuthSessionsIp < Sequel::Model(:ui_auth_sessions_ips)
  unrestrict_primary_key

  many_to_one :ui_auth_session
end
