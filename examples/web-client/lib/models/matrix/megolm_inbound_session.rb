# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class MegolmInboundSession < Sequel::Model(:matrix_megolm_inbound_sessions)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :signing_key, :sender_data, :forwarder_data

      def validate
        super
        validates_presence :session_id
        validates_presence %i[room_id sender_key pickle]
        validates_unique :session_id
      end

      def self.store!(room_id:, session_id:, sender_key:, session_key:)
        if where(session_id: session_id).any?
          nil
        else
          inbound = Async::Matrix::E2EE::InboundGroupSession.new(session_key)
          persist!(
            room_id:    room_id,
            session_id: session_id,
            sender_key: sender_key,
            inbound:    inbound,
          )
        end
      end

      def self.import!(room_id:, session_id:, sender_key:, exported_key:)
        if where(session_id: session_id).any?
          nil
        else
          inbound = Async::Matrix::E2EE::InboundGroupSession.import(exported_key)
          persist!(
            room_id:    room_id,
            session_id: session_id,
            sender_key: sender_key,
            inbound:    inbound,
          )
        end
      end

      def self.persist!(room_id:, session_id:, sender_key:, inbound:)
        create(
          room_id:    room_id,
          session_id: session_id,
          sender_key: sender_key,
          pickle:     inbound.pickle(::Matrix::Device::Crypto.pickle_key),
        )
      end

      def session
        @session ||= Async::Matrix::E2EE::InboundGroupSession.from_pickle(
          pickle, ::Matrix::Device::Crypto.pickle_key,
        )
      end
    end
  end
end

__END__

create_table?(:matrix_megolm_inbound_sessions) do
  primary_key :id, type: :Bignum, serial: true
  column      :created_at, TIMESTAMP, null: false
  column      :pickle, :text, null: false
  column      :room_id, TEXT, null: false
  column      :sender_key, TEXT, null: false
  column      :session_id, TEXT, null: false
  column      :updated_at, TIMESTAMP, null: false

  # The rest of PickledInboundGroupSession.
  #
  # The pickle is {pickle, sender_key, signing_key, sender_data,
  # forwarder_data, room_id, imported, backed_up} and this table held
  # four of those. `signing_key` is the one that was actively being
  # dropped: Async::Matrix::DeviceStore#export emits it on every group
  # session and there was no column to put it in.
  #
  # SIGNING KEY IS NOT DECORATION. It is the claimed ed25519 of the
  # sender, and it is what makes a decrypted message attributable: a
  # message decrypted by a session whose signing key you did not record
  # is a message you cannot say came from anyone.
  column      :signing_key, :blob, default: Sequel.lit("'{}'"), null: false

  # How the sender of this key was established -- SenderData is a
  # ladder (UnknownDevice -> DeviceInfo -> SenderUnverified ->
  # SenderVerified) and the type is stored alongside it because the
  # crypto store indexes on it when deciding what to re-check.
  column      :sender_data, :blob, default: Sequel.lit("'{}'"), null: false
  column      :sender_data_type, :integer

  # Whether this session reached the server-side key backup, and whether
  # it came from one (or from an import / forward) rather than from a
  # live m.room_key. Both change what the UI may claim about a message's
  # provenance, and `backed_up` is what makes incremental backup
  # possible at all.
  column      :backed_up, :boolean, default: false, null: false
  column      :imported, :boolean, default: false, null: false
  column      :forwarder_data, :blob

  index :room_id, name: :index_matrix_megolm_inbound_sessions_on_room_id
  index :session_id, unique: true, name: :index_matrix_megolm_inbound_sessions_on_session_id

end

