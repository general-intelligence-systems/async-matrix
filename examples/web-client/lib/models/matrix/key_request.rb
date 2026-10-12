# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    # Room keys we have asked other devices to re-send, and whether we asked.
    #
    # This is the recovery path for the message that arrives before its key.
    # Without it, an undecryptable event stays undecryptable unless the sender
    # happens to re-share -- which is why matrix_events.decryption_error
    # existed with nothing able to clear it.
    class KeyRequest < Sequel::Model(:matrix_key_requests)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :info, :content

      def validate
        super
        validates_presence :request_id
        validates_unique :request_id
      end

      dataset_module do
        # Not yet asked for. The to-device send drains this.
        def unsent = where(sent_out: false)
        def sent   = where(sent_out: true)

        # Which request an arriving room key answers. `info` carries room_id /
        # sender_key / session_id / algorithm, and the session id is the part
        # that identifies the key.
        #
        # Written as a literal rather than through Sequel.pg_jsonb_op, which
        # needs the pg_json_ops extension loaded -- nothing here loads it, and a
        # scope that raises NoMethodError on first use is worse than `->>`.
        def for_session(session_id)
          where(Sequel.lit("info ->> 'session_id' = ?", session_id))
        end
      end

      def sent? = !!sent_out

      def session_id = info["session_id"]
      def room_id    = info["room_id"]

      # The events this key would unlock, so that a cancelled or answered
      # request can say what it was for.
      def blocked_events
        Event.where(room_id: room_id, session_id: session_id)
      end
    end
  end
end

__END__

create_table?(:matrix_key_requests) do
  primary_key :id, type: :Bignum, serial: true
  column      :request_id, TEXT, null: false
  column      :sent_out, :boolean, default: false, null: false
  # room_id / sender_key / session_id / algorithm: what was asked for,
  # indexed so an arriving key can be matched to the request it answers.
  column      :info, :blob, default: Sequel.lit("'{}'"), null: false
  column      :content, :blob, default: Sequel.lit("'{}'"), null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index :request_id, unique: true, name: :index_matrix_key_requests_on_request_id
  index :sent_out, name: :index_matrix_key_requests_on_sent_out
end
