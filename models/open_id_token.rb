class OpenIdToken < Sequel::Model(:open_id_tokens)
  unrestrict_primary_key
  set_primary_key :token
end
