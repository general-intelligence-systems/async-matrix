# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    class OlmSession < Sequel::Model(:matrix_olm_sessions)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence :session_id
        validates_presence %i[sender_key pickle]
        validates_unique :session_id
      end

      dataset_module do
        def with_peer(sender_key)
          where(sender_key: sender_key).order(Sequel.lit("last_used_at DESC NULLS LAST"))
        end
      end

      def session
        @session ||= Async::Matrix::E2EE::Session.from_pickle(
          pickle, ::Matrix::Device::Crypto.pickle_key,
        )
      end

      def save_session!
        update(
          pickle:       session.pickle(::Matrix::Device::Crypto.pickle_key),
          last_used_at: Time.now,
        )
      end

      def self.persist!(sender_key:, session:)
        create(
          sender_key:   sender_key,
          session_id:   session.session_id,
          pickle:       session.pickle(::Matrix::Device::Crypto.pickle_key),
          last_used_at: Time.now,
        )
      end
    end
  end
end

__END__

create_table?(:matrix_olm_sessions) do
  primary_key :id, type: :Bignum, serial: true
  column      :created_at, TIMESTAMP, null: false
  column      :last_used_at, TIMESTAMP
  column      :pickle, :text, null: false
  column      :sender_key, TEXT, null: false
  column      :session_id, TEXT, null: false
  column      :updated_at, TIMESTAMP, null: false

  #
  # PickledSession also carries creation_time and last_use_time, which
  # `created_at` and `last_used_at` already cover. This is the one field
  # with no equivalent: a session opened against a FALLBACK key is not
  # as trustworthy as one opened against a one-time key, because a
  # fallback key is reused and therefore replayable.
  column      :created_using_fallback_key, :boolean, default: false, null: false

  index :sender_key, name: :index_matrix_olm_sessions_on_sender_key
  index :session_id, unique: true, name: :index_matrix_olm_sessions_on_session_id

end

