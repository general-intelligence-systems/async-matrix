# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # Secrets gossiped to us by our own other devices over to-device
    # messages: the cross-signing private keys and the key-backup decryption
    # key, which is how a newly verified device gets what it needs without the
    # user typing a recovery passphrase.
    #
    # An INBOX, not a store. Several devices may send the same secret and they
    # are not all necessarily trustworthy, so the rows accumulate and the
    # consumer picks; matrix_credentials.recovery_key is where the accepted
    # one ends up.
    class SecretsInbox < Sequel::Model(:matrix_secrets_inbox)
      # The secrets a device gossips, by their spec'd names. The three
      # cross-signing private keys and the key-backup decryption key, which
      # together are everything a newly verified device needs.
      MASTER       = "m.cross_signing.master"
      SELF_SIGNING = "m.cross_signing.self_signing"
      USER_SIGNING = "m.cross_signing.user_signing"
      MEGOLM_BACKUP = "m.megolm_backup.v1"
      NAMES = [MASTER, SELF_SIGNING, USER_SIGNING, MEGOLM_BACKUP].freeze

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      # DELIBERATELY NOT UNIQUE on (user_id, secret_name): the index in the
      # migration is not either. Several devices may send the same secret and
      # they are not all necessarily trustworthy, so the rows accumulate and the
      # consumer picks.
      def validate
        super
        validates_presence %i[secret_name secret]
      end

      dataset_module do
        def named(secret_name) = where(secret_name: secret_name)

        # Most recent first, which is the order a consumer that has no better
        # reason to prefer one sender over another should take them in.
        def newest_first = order(Sequel.desc(:created_at))

        # Only what a device we have verified sent us. The caller supplies the
        # device ids because trust lives in matrix_devices, not here.
        def from_devices(device_ids) = where(sender_device_id: device_ids)
      end

      # The sending device, if it is one we know. Always one of OUR OWN, so the
      # caller supplies which Matrix user that is -- a device id is unique only
      # within a user, and matrix_devices holds everyone's.
      def sender(matrix_user_id)
        Device.first(
          matrix_user_id: matrix_user_id,
          device_id:      sender_device_id,
        )
      end
    end
  end
end

__END__

create_table?(:matrix_secrets_inbox) do
  primary_key :id, type: :Bignum, serial: true
  column      :secret_name, TEXT, null: false
  column      :secret, :text, null: false
  column      :sender_device_id, TEXT
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index :secret_name, name: :index_matrix_secrets_inbox_on_secret_name
end
