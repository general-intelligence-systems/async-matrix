class EventTxnId < Sequel::Model(:event_txn_id)
  unrestrict_primary_key

  many_to_one :event, key: :event_id
  many_to_one :access_token, key: :token_id
end
