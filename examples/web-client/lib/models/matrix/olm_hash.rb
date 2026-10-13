# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    class OlmHash < Sequel::Model(:matrix_olm_hashes)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence %i[sender_key message_hash]
      end

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
