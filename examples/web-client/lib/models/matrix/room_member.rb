# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # One member of one room, in one user's view. Written by Matrix::Device::Sync
    # from m.room.member state, read by clients over Electric.
    class RoomMember < Sequel::Model(:matrix_room_members)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def validate
        super
        validates_presence :member_id
        validates_unique %i[room_id member_id]
      end

      dataset_module do
        def joined = where(membership: "join")
      end

      # What the UI shows: the display name when the room has one, else the raw id.
      def name
        if display_name.to_s.empty?
          member_id
        else
          display_name
        end
      end
    end
  end
end

__END__

create_table?(:matrix_room_members) do
  primary_key :id, type: :Bignum, serial: true
  column      :avatar_url, TEXT
  column      :created_at, TIMESTAMP, null: false
  column      :display_name, TEXT
  column      :member_id, TEXT, null: false
  column      :membership, TEXT, default: "join", null: false
  column      :power_level, :integer, default: 0, null: false
  column      :room_id, TEXT, null: false
  column      :updated_at, TIMESTAMP, null: false

  #
  # A STRIPPED MEMBER IS NOT A MEMBER. Invite state arrives as stripped
  # events -- no event_id, no origin_server_ts, no guarantee of
  # completeness -- and the state store flags them so that a room you
  # have only been invited to does not claim to know its membership.
  # Without this, the invite's handful of stripped members are
  # indistinguishable from a synced member list.
  column      :stripped, :boolean, default: false, null: false

  index %i[room_id member_id],
    unique: true,
    name:   :index_matrix_room_members_on_room_id_and_member_id
  index :room_id, name: :index_matrix_room_members_on_room_id

end

