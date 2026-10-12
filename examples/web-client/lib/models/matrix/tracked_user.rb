# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # Whose device list we are following, and whose we know to be stale.
    #
    # `dirty` is set by /sync's `device_lists.changed` and cleared by the
    # /keys/query that answers it. Without it there is no way to know a
    # device list needs refetching except to refetch all of them, which is
    # the request this flag exists to avoid.
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
        # The /keys/query batch. Dirty rows only, which is the request the
        # `dirty` flag exists to narrow.
        def dirty = where(dirty: true)
        def clean = where(dirty: false)
      end

      # Start following someone's device list. New rows are dirty by default:
      # we have the user id and nothing else, so the first /keys/query is owed
      # regardless.
      def self.track!(matrix_user_id:)
        first(matrix_user_id: matrix_user_id) ||
          create(matrix_user_id: matrix_user_id)
      end

      # What /sync's device_lists.changed means: these lists are stale.
      def self.mark_dirty!(matrix_user_ids:)
        where(matrix_user_id: matrix_user_ids).update(dirty: true)
      end

      # And what the /keys/query that answered it means.
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
