class Redaction < Sequel::Model(:redactions)
  unrestrict_primary_key

  many_to_one :event
end
