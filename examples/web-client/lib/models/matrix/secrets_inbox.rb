# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    class SecretsInbox < Sequel::Model(:matrix_secrets_inbox)
      MASTER       = "m.cross_signing.master"
      SELF_SIGNING = "m.cross_signing.self_signing"
      USER_SIGNING = "m.cross_signing.user_signing"
      MEGOLM_BACKUP = "m.megolm_backup.v1"
      NAMES = [MASTER, SELF_SIGNING, USER_SIGNING, MEGOLM_BACKUP].freeze

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence %i[secret_name secret]
      end

      dataset_module do
        def named(secret_name) = where(secret_name: secret_name)

        def newest_first = order(Sequel.desc(:created_at))

      end
    end
  end
end

__END__

create_table?(:matrix_secrets_inbox) do
  primary_key :id, type: :Bignum, serial: true
  column      :secret_name, TEXT, null: false
  column      :secret, :text, null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index :secret_name, name: :index_matrix_secrets_inbox_on_secret_name
end
