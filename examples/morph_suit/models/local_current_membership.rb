class LocalCurrentMembership < Sequel::Model(:local_current_membership)
  unrestrict_primary_key

  many_to_one :room
end
