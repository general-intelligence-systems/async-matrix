# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class VerificationFlow < Sequel::Model(:matrix_verification_flows)
      REQUESTED = "requested"

      READY = "ready"

      STARTED = "started"

      ACCEPTED = "accepted"

      KEYED = "keyed"

      CONFIRMED = "confirmed"

      DONE = "done"

      CANCELLED = "cancelled"

      LIVE = [REQUESTED, READY, STARTED, ACCEPTED, KEYED, CONFIRMED].freeze

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :methods_offered, :emoji, :decimals, :their_keys

      def validate
        super
        validates_presence [:flow_id, :other_user_id, :state]
      end

      dataset_module do
        def live = where(state: LIVE)

        def newest_first = order(Sequel.desc(:created_at))
      end

      def live? = LIVE.include?(state)

      def own? = !!own

      def sas? = methods_offered.to_a.include?("m.sas.v1")
    end
  end
end

__END__

create_table?(:matrix_verification_flows) do
  primary_key :id, type: :Bignum, serial: true
  column      :flow_id, TEXT, null: false
  column      :other_user_id, TEXT, null: false
  column      :other_device_id, TEXT
  column      :room_id, TEXT
  column      :own, :boolean, default: false, null: false
  column      :started_by_us, :boolean, default: false, null: false
  column      :state, TEXT, null: false
  column      :methods_offered, :blob, default: Sequel.lit("'[]'"), null: false
  column      :verification_method, TEXT
  column      :key_agreement_protocol, TEXT
  column      :hash_method, TEXT
  column      :message_authentication_code, TEXT
  column      :commitment, TEXT
  column      :their_key, TEXT
  column      :their_keys, :blob, default: Sequel.lit("'{}'"), null: false
  column      :emoji, :blob, default: Sequel.lit("'[]'"), null: false
  column      :decimals, :blob, default: Sequel.lit("'[]'"), null: false
  column      :cancel_code, TEXT
  column      :cancel_reason, TEXT
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index [:flow_id], unique: true
end
