# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    # Room key bundles (MSC4268): the history a room's inviter shares with an
    # invitee so the new member can read what came before them.
    #
    # `state` covers both of the SDK's tables -- it tracks a bundle we expect
    # ("pending", we invited someone and owe them one) and one we received
    # ("received", waiting to be imported) in one place, because they are the
    # same object at two points in its life.
    class RoomKeyBundle < Sequel::Model(:matrix_room_key_bundles)
      # The two points in one bundle's life -- see the class comment for why
      # they are one table.
      #
      # PENDING is ours to send: we invited someone and owe them history.
      # RECEIVED is theirs to us, waiting to be imported. IMPORTED is the end of
      # it, kept so the import is not attempted twice.
      PENDING  = "pending"
      RECEIVED = "received"
      IMPORTED = "imported"
      STATES   = [PENDING, RECEIVED, IMPORTED].freeze

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :bundle

      def validate
        super
        validates_presence :room_id
        validates_includes STATES, :state
        validates_unique %i[room_id sender_user_id]
      end

      dataset_module do
        def pending  = where(state: PENDING)
        def received = where(state: RECEIVED)

        # What the importer drains: a bundle we hold and have not read yet.
        def importable = where(state: RECEIVED).exclude(bundle: nil)
      end

      def imported? = state == IMPORTED

      # The bundle is in. Keeps the row and drops the payload, which is a pile
      # of room keys we now hold in matrix_megolm_inbound_sessions.
      def imported!
        update(state: IMPORTED, bundle: nil)
      end
    end
  end
end

__END__

create_table?(:matrix_room_key_bundles) do
  primary_key :id, type: :Bignum, serial: true
  column      :room_id, TEXT, null: false
  column      :sender_user_id, TEXT
  column      :state, TEXT, default: "pending", null: false
  column      :bundle, :blob
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[room_id sender_user_id],
    unique: true,
    name:   :index_matrix_room_key_bundles_on_room_id_and_sender_user_id
  index :state, name: :index_matrix_room_key_bundles_on_state
end
