# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    # Cross-signing identities, ours and everyone else's.
    #
    # The three keys are the spec's: master signs the other two, self-signing
    # signs your own devices, user-signing signs other people's master keys.
    # `own` separates our identity from the rest, because only ours has a
    # user-signing key we hold the private half of.
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
        # Ours. There is at most one, and it is the only row whose
        # user_signing_key we hold the private half of.
        def own = where(own: true)

        def others   = where(own: false)
        def verified = where(verified: true)
      end

      def own? = !!own

      # An identity with no master key is a row we created to hang a device off,
      # not a cross-signing identity -- nothing can be verified against it.
      def cross_signed? = !master_key.nil?

      # This identity's devices. The self-signing key is what signs them, which
      # is why trusting the master key transitively trusts the list.
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
