# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
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
        def unsent = where(sent_out: false)
        def sent   = where(sent_out: true)

        def for_session(session_id)
          where(Sequel.lit("info ->> 'session_id' = ?", session_id))
        end
      end

      def sent? = !!sent_out

      def session_id = info["session_id"]
      def room_id    = info["room_id"]

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
