# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class UserIdentity < Sequel::Model(:matrix_user_identities)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :master_key, :self_signing_key, :user_signing_key

      def validate
        super
        validates_presence :matrix_user_id
        validates_unique :matrix_user_id
      end

      dataset_module do
        def own = where(own: true)

        def others   = where(own: false)
        def verified = where(verified: true)
      end

      def own? = !!own

      def cross_signed? = !master_key.nil?

      def devices
        Device.where(matrix_user_id: matrix_user_id)
      end
    end
  end
end

__END__

create_table?(:matrix_user_identities) do
  primary_key :id, type: :Bignum, serial: true
  column      :matrix_user_id, TEXT, null: false
  column      :own, :boolean, default: false, null: false
  column      :master_key, :blob
  column      :self_signing_key, :blob
  column      :user_signing_key, :blob
  column      :verified, :boolean, default: false, null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index :matrix_user_id, unique: true, name: :index_matrix_user_identities_on_matrix_user_id
end
