# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    class DeviceState < Sequel::Model(:matrix_device_states)
      OTK_THRESHOLD_RATIO = 0.5

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence :account_pickle
      end

      def self.current
        first || create_account!
      end

      def self.create_account!
        account = Async::Matrix::E2EE::Account.new
        create(
          account_pickle: account.pickle(::Matrix::Device::Crypto.pickle_key),
        )
      end

      def account
        @account ||= Async::Matrix::E2EE::Account.from_pickle(
          account_pickle, ::Matrix::Device::Crypto.pickle_key,
        )
      end

      def save_account!
        update(account_pickle: account.pickle(::Matrix::Device::Crypto.pickle_key))
      end

      def needs_one_time_keys?
        otk_count < (account.max_number_of_one_time_keys * OTK_THRESHOLD_RATIO).floor
      end
    end
  end
end

__END__

create_table?(:matrix_device_states) do
  primary_key :id, type: :Bignum, serial: true
  column      :account_pickle, :text, null: false
  column      :created_at, TIMESTAMP, null: false
  column      :keys_published, :boolean, default: false, null: false
  column      :otk_count, :integer, default: 0, null: false
  column      :updated_at, TIMESTAMP, null: false

  # The rest of PickledAccount.
  #
  # matrix-sdk-crypto pickles an account as {user_id, device_id, pickle,
  # shared, dehydrated, uploaded_signed_key_count, creation_local_time,
  # fallback_key_creation_timestamp}. The first four already had columns
  # (`shared` is `keys_published`, the key count is `otk_count`); these
  # are the three that did not.
  column      :dehydrated, :boolean, default: false, null: false
  column      :creation_local_time, :bigint
  column      :fallback_key_created_at, :bigint


end

