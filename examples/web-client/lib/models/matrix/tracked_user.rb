# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    class TrackedUser < Sequel::Model(:matrix_tracked_users)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence :matrix_user_id
        validates_unique :matrix_user_id
      end

      dataset_module do
        def dirty = where(dirty: true)
        def clean = where(dirty: false)
      end

      def self.track!(matrix_user_id:)
        first(matrix_user_id: matrix_user_id) ||
          create(matrix_user_id: matrix_user_id)
      end

      def self.mark_dirty!(matrix_user_ids:)
        where(matrix_user_id: matrix_user_ids).update(dirty: true)
      end

      def self.mark_clean!(matrix_user_ids:)
        where(matrix_user_id: matrix_user_ids).update(dirty: false)
      end
    end
  end
end

__END__

create_table?(:matrix_tracked_users) do
  primary_key :id, type: :Bignum, serial: true
  column      :matrix_user_id, TEXT, null: false
  column      :dirty, :boolean, default: true, null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index :matrix_user_id, unique: true, name: :index_matrix_tracked_users_on_matrix_user_id
  index :dirty, name: :index_matrix_tracked_users_on_dirty
end
