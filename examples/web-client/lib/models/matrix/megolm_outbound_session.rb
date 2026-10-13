# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class MegolmOutboundSession < Sequel::Model(:matrix_megolm_outbound_sessions)
      DEFAULT_ROTATION_MSGS = 100
      DEFAULT_ROTATION_MS   = 7 * 24 * 60 * 60 * 1000

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :shared_with

      def validate
        super
        validates_presence :room_id
        validates_presence %i[session_id pickle]
        validates_unique :room_id
      end

      def session
        @session ||= Async::Matrix::E2EE::GroupSession.from_pickle(
          pickle, ::Matrix::Device::Crypto.pickle_key,
        )
      end

      def save_session!
        update(
          pickle:        session.pickle(::Matrix::Device::Crypto.pickle_key),
          message_count: message_count + 1,
        )
      end

      def expired?(rotation_msgs: DEFAULT_ROTATION_MSGS, rotation_ms: DEFAULT_ROTATION_MS)
        message_count >= rotation_msgs ||
          started_at <= Time.now - (rotation_ms / 1000.0)
      end

      def shared_with?(matrix_user_id, device_id)
        Array(shared_with[matrix_user_id]).include?(device_id)
      end

      def record_shared!(targets)
        merged = shared_with.to_h.dup
        targets.each do |matrix_user_id, device_ids|
          merged[matrix_user_id] = (Array(merged[matrix_user_id]) | Array(device_ids))
        end
        update(shared_with: merged)
      end

      def self.rotate!(room_id:)
        group  = Async::Matrix::E2EE::GroupSession.new
        record = first(room_id: room_id) ||
          new(room_id: room_id)

        record.set(
          session_id:    group.session_id,
          pickle:        group.pickle(::Matrix::Device::Crypto.pickle_key),
          message_count: 0,
          started_at:    Time.now,
          shared_with:   {},
        )
        record.save
      end
    end
  end
end

__END__

create_table?(:matrix_megolm_outbound_sessions) do
  primary_key :id, type: :Bignum, serial: true
  column      :created_at, TIMESTAMP, null: false
  column      :message_count, :integer, default: 0, null: false
  column      :pickle, :text, null: false
  column      :room_id, TEXT, null: false
  column      :session_id, TEXT, null: false
  column      :shared_with, :blob, default: Sequel.lit("'{}'"), null: false
  column      :started_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index :room_id, unique: true, name: :index_matrix_megolm_outbound_sessions_on_room_id

end
