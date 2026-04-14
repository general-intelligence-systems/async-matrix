class UiAuthSession < Sequel::Model(:ui_auth_sessions)
  unrestrict_primary_key
  set_primary_key :session_id
end
