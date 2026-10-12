# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    # The room key we SEND with — one live session per room.
    #
    # Rotation is a security property, not housekeeping: everyone holding the
    # current key can read everything encrypted with it, so a member leaving must
    # force a new one. #expired? covers the time/count policy from m.room.encryption;
    # membership changes call #rotate! directly.
    class MegolmOutboundSession < Sequel::Model(:matrix_megolm_outbound_sessions)
      # Spec defaults for m.room.encryption when the room doesn't override them.
      DEFAULT_ROTATION_MSGS = 100
      # 7 days. ActiveSupport's 7.days.in_milliseconds, written out.
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

      # Megolm ratchets forward on every message, so persist after each encrypt or
      # the next one reuses a message index — which peers reject as a replay.
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

      # Has this device already been given the current key? Re-sharing to everyone on
      # every message would be correct but wasteful; we only target new devices.
      def shared_with?(matrix_user_id, device_id)
        Array(shared_with[matrix_user_id]).include?(device_id)
      end

      # `.to_h.dup` where ActiveRecord had `deep_dup`: every branch below
      # ASSIGNS a freshly built array rather than mutating one in place, so
      # nothing nested is ever touched and a shallow copy is the whole need.
      def record_shared!(targets)
        merged = shared_with.to_h.dup
        targets.each do |matrix_user_id, device_ids|
          merged[matrix_user_id] = (Array(merged[matrix_user_id]) | Array(device_ids))
        end
        update(shared_with: merged)
      end

      # Start a fresh session for this room, discarding the old one. The new key is
      # distributed lazily by Matrix::Device::Keys on the next send.
      # `first || new` then `set` + `save` is ActiveRecord's
      # `find_or_initialize_by(...).update!(...)`: Sequel's #update is
      # set-plus-save_changes and save_changes is for persisted rows only, so a
      # row that does not exist yet has to be saved rather than updated. #save
      # returns the record either way.
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
