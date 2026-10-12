# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # Olm prekey message replay protection.
    #
    # Async::Matrix::DeviceStore does this check in memory
    # (`check_olm_replay`), which holds for the life of the process and
    # forgets on restart -- and a forgotten replay window is a replay window.
    # The spec's requirement is that a prekey message already seen is not
    # processed again, which only means anything if "already seen" outlives
    # the process.
    class OlmHash < Sequel::Model(:matrix_olm_hashes)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      # NO validates_unique HERE, deliberately, and it is the only model in this
      # directory whose unique index has no validation beside it.
      #
      # The uniqueness is the replay check itself rather than a data-entry
      # mistake to report, and validates_unique answers it with a SELECT -- two
      # fibers decrypting the same replayed message would both read "unseen" and
      # both proceed. The INSERT is what one of them has to lose, so the insert
      # is what asks. It also saves a query per prekey message, on the one path
      # here that runs per inbound to-device message.
      def validate
        super
        validates_presence %i[sender_key message_hash]
      end

      # Record a prekey message, or report that it has been seen before.
      def self.record!(sender_key:, message_hash:)
        create(sender_key: sender_key, message_hash: message_hash)
        true
      rescue Sequel::UniqueConstraintViolation
        false
      end

      def self.seen?(sender_key:, message_hash:)
        where(sender_key: sender_key, message_hash: message_hash).any?
      end
    end
  end
end

__END__

create_table?(:matrix_olm_hashes) do
  primary_key :id, type: :Bignum, serial: true
  column      :sender_key, TEXT, null: false
  column      :message_hash, TEXT, null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[sender_key message_hash],
    unique: true,
    name:   :index_matrix_olm_hashes_on_sender_key_and_message_hash
end
