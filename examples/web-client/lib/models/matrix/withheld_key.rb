# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # Keys someone deliberately did not send us, and why.
    #
    # m.room_key.withheld is the difference between "this message is broken"
    # and "the sender chose not to let you read this because your device is
    # unverified" -- which is a sentence a UI can show and act on, where a
    # decryption failure is not.
    class WithheldKey < Sequel::Model(:matrix_withheld_keys)
      # m.room_key.withheld's codes, and the sentence each one is. The reasons
      # are here because they are what makes this table worth having: a UI can
      # show one, where it cannot show a decryption failure.
      UNVERIFIED   = "m.unverified"
      BLACKLISTED  = "m.blacklisted"
      UNAUTHORISED = "m.unauthorised"
      NO_OLM       = "m.no_olm"
      CODES        = [UNVERIFIED, BLACKLISTED, UNAUTHORISED, NO_OLM].freeze

      MESSAGES = {
        UNVERIFIED   => "The sender did not share this message with unverified devices.",
        BLACKLISTED  => "The sender has blocked this device.",
        UNAUTHORISED => "The sender did not consider this device authorised to read this.",
        NO_OLM       => "The sender had no way to reach this device with the key.",
      }.freeze

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence %i[room_id session_id]
        validates_includes CODES, :code
        validates_unique :session_id
      end

      dataset_module do
        def in_room(room_id) = where(room_id: room_id)
      end

      # What to show instead of "unable to decrypt". The sender's own `reason`
      # wins when they sent one, since they know more than the code does.
      def explanation
        if reason.to_s.empty?
          MESSAGES.fetch(code, "The sender did not share this message's key.")
        else
          reason
        end
      end

      # The events this withholding accounts for.
      def events
        Event.where(room_id: room_id, session_id: session_id)
      end
    end
  end
end

__END__

create_table?(:matrix_withheld_keys) do
  primary_key :id, type: :Bignum, serial: true
  column      :room_id, TEXT, null: false
  column      :session_id, TEXT, null: false
  column      :sender_key, TEXT
  # m.unverified / m.blacklisted / m.unauthorised / m.no_olm.
  column      :code, TEXT, null: false
  column      :reason, :text
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index :session_id, unique: true, name: :index_matrix_withheld_keys_on_session_id
  index :room_id, name: :index_matrix_withheld_keys_on_room_id
end
