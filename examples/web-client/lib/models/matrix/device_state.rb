# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # The server device's Olm account and sync position — one row per user.
    #
    # Pairs with Matrix::Credential: that holds WHO the device is to the homeserver
    # (device_id + tokens), this holds WHAT it knows cryptographically. Both are
    # durable for the same reason — a Matrix device is a crypto identity, and
    # re-minting one throws away every room key it ever received.
    class DeviceState < Sequel::Model(:matrix_device_states)
      # Below this many unclaimed one-time keys on the server, top up. The spec
      # suggests keeping around half of max_number_of_one_time_keys available; going
      # empty means other devices can't establish an Olm session with us, which
      # shows up as "unable to decrypt" on THEIR side, not ours.
      OTK_THRESHOLD_RATIO = 0.5

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence :account_pickle
      end

      # This user's device state, creating the Olm account on first use. The account
      # is generated once and then never replaced — see the class comment.
      def self.for(user)
        first(user_id: user.id) || create_account!(user)
      end

      def self.create_account!(user)
        account = Async::Matrix::E2EE::Account.new
        create(
          user_id:        user.id,
          account_pickle: account.pickle(::Matrix::Device::Crypto.pickle_key),
        )
      end

      # The live vodozemac Account. Mutating it (generating keys, creating sessions)
      # changes only this in-memory copy — persist with #save_account!.
      def account
        @account ||= Async::Matrix::E2EE::Account.from_pickle(
          account_pickle, ::Matrix::Device::Crypto.pickle_key,
        )
      end

      # Re-pickle the account after any operation that advanced its state. Olm
      # accounts are stateful (one-time keys are consumed), so failing to save after
      # creating an inbound session loses the ability to decrypt that peer's next
      # message.
      def save_account!
        update(account_pickle: account.pickle(::Matrix::Device::Crypto.pickle_key))
      end

      # Should we upload more one-time keys? Compared against what the last /sync
      # said the server still holds, not against what we generated.
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
  column      :sync_token, TEXT
  column      :updated_at, TIMESTAMP, null: false
  column      :user_id, :bigint, null: false

  # ── Beyond the Rails schema: the rest of PickledAccount ────────────
  #
  # matrix-sdk-crypto pickles an account as {user_id, device_id, pickle,
  # shared, dehydrated, uploaded_signed_key_count, creation_local_time,
  # fallback_key_creation_timestamp}. The first four already had columns
  # (`shared` is `keys_published`, the key count is `otk_count`); these
  # are the three that did not.
  column      :dehydrated, :boolean, default: false, null: false
  column      :creation_local_time, :bigint
  column      :fallback_key_created_at, :bigint

  index :user_id, unique: true, name: :index_matrix_device_states_on_user_id
end

# The same columns again, for a database that already has this table -- an
# import of the Rails app's ten. create_table? above is a no-op there, so
# without this not one of them would ever be created. See
# Migrations.added_columns.
added_columns(
  [:dehydrated, :boolean, {default: false, null: false}],
  [:creation_local_time, :bigint, {}],
  [:fallback_key_created_at, :bigint, {}],
)
