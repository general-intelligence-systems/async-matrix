# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    # Which display names are claimed by more than one member of a room.
    #
    # DISAMBIGUATION IS A SAFETY FEATURE, not a nicety: the spec requires that
    # a display name shared by two members be shown with the user id appended,
    # because otherwise anyone can set their name to yours and be quoted as
    # you. Deciding that per render means counting the room's members on every
    # message; this is that count, maintained as membership changes.
    class MemberDisplayName < Sequel::Model(:matrix_member_display_names)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :member_ids

      def validate
        super
        validates_presence %i[room_id display_name]
        validates_unique %i[user_id room_id display_name]
      end

      dataset_module do
        def in_room(room_id) = where(room_id: room_id)
      end

      # The safety question, and the only one this table is for: does showing
      # this name alone identify one person? See the class comment.
      def ambiguous? = member_ids.length > 1

      # What to render. The spec's rule: a shared name is shown with the user id
      # appended, so that nobody can be quoted as someone else.
      def disambiguated(member_id)
        if ambiguous?
          "#{display_name} (#{member_id})"
        else
          display_name
        end
      end

      # How a room member should be labelled, counting the claims on their name.
      # The fallback is the raw id, which is never ambiguous.
      def self.render(user_id:, room_id:, member_id:, display_name:)
        if display_name.to_s.empty?
          member_id
        else
          row = first(user_id: user_id, room_id: room_id, display_name: display_name)
          row&.disambiguated(member_id) || display_name
        end
      end
    end
  end
end

__END__

create_table?(:matrix_member_display_names) do
  primary_key :id, type: :Bignum, serial: true
  column      :user_id, :bigint, null: false
  column      :room_id, TEXT, null: false
  column      :display_name, TEXT, null: false
  column      :member_ids, :blob, default: Sequel.lit("jsonb('[]')"), null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[user_id room_id display_name],
    unique: true,
    name:   :index_matrix_member_display_names_on_user_id_and_room_and_name
end
