# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class MemberDisplayName < Sequel::Model(:matrix_member_display_names)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :member_ids

      def validate
        super
        validates_presence %i[room_id display_name]
        validates_unique %i[room_id display_name]
      end

      dataset_module do
        def in_room(room_id) = where(room_id: room_id)
      end

      def ambiguous? = member_ids.length > 1

      def disambiguated(member_id)
        if ambiguous?
          "#{display_name} (#{member_id})"
        else
          display_name
        end
      end

      def self.render(room_id:, member_id:, display_name:)
        if display_name.to_s.empty?
          member_id
        else
          row = first(room_id: room_id, display_name: display_name)
          row&.disambiguated(member_id) || display_name
        end
      end
    end
  end
end

__END__

create_table?(:matrix_member_display_names) do
  primary_key :id, type: :Bignum, serial: true
  column      :room_id, TEXT, null: false
  column      :display_name, TEXT, null: false
  column      :member_ids, :blob, default: Sequel.lit("'[]'"), null: false
  column      :created_at, TIMESTAMP, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[room_id display_name],
    unique: true,
    name:   :index_matrix_member_display_names_on_room_id_and_display_name
end
