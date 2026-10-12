# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # A user's profile independent of any room, for the places that have a
    # user id and no room to look them up in: the invite list, search
    # results, a mention of someone who left.
    class GlobalProfile < Sequel::Model(:matrix_global_profiles)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence :matrix_user_id
        validates_unique :matrix_user_id
      end

      # What the UI shows: the profile name when there is one, else the raw id.
      # Same rule as RoomMember#name, and deliberately so -- a global profile is
      # the fallback for the places that have no room to ask.
      def name
        if display_name.to_s.empty?
          matrix_user_id
        else
          display_name
        end
      end

      # The localpart, for the places that show @alice rather than
      # @alice:example.org.
      def localpart = matrix_user_id.to_s.sub(/\A@/, "").split(":").first
    end
  end
end

__END__

create_table?(:matrix_global_profiles) do
  primary_key :id, type: :Bignum, serial: true
  column      :matrix_user_id, TEXT, null: false
  column      :display_name, TEXT
  column      :avatar_url, TEXT
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index :matrix_user_id, unique: true, name: :index_matrix_global_profiles_on_matrix_user_id
end
