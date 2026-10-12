# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    # One room in one user's room list, as the server device sees it.
    #
    # Written only by Matrix::Device::Sync and read only by Electric — no controller
    # mutates this. A client that wants to change a room (rename, invite, leave)
    # posts to the engine's endpoints, which acts through the device; the change then
    # comes back down through sync like any other, so there is exactly one direction
    # of truth.
    class Room < Sequel::Model(:matrix_rooms)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb(
        :children, :pinned, :power_levels, :alt_aliases,
        :join_rule_allow, :encryption, :heroes, :tags,
        :retention, :member_hints, :rtc_members,
      )

      def validate
        super
        validates_presence :room_id
        validates_unique :room_id
      end

      dataset_module do
        def joined = where(membership: "join")

        # Sidebar order: most recent activity first, nulls (never-used rooms) last.
        def by_activity = order(Sequel.lit("last_activity_at DESC NULLS LAST"))
      end

      def events
        Event.where(room_id: room_id)
      end

      def members
        RoomMember.where(room_id: room_id)
      end

      # Power level required for +action+ ("kick", "ban", "invite", "redact"), or the
      # events_default / state_default fallback the spec defines. Mirrors what the
      # client derives for ChatPermissions, kept here for server-side checks.
      def power_level_for(action, default: 50)
        power_levels[action.to_s] || default
      end

      # A member's effective power level: their explicit entry, else users_default.
      def power_level_of(member_id)
        power_levels.dig("users", member_id) || power_levels["users_default"] || 0
      end
    end
  end
end

__END__

create_table?(:matrix_rooms) do
  primary_key :id, type: :Bignum, serial: true
  column      :avatar_url, TEXT
  column      :children, :blob, default: Sequel.lit("'[]'"), null: false
  column      :created_at, TIMESTAMP, null: false
  column      :direct, :boolean, default: false, null: false
  column      :encrypted, :boolean, default: false, null: false
  column      :highlight_count, :integer, default: 0, null: false
  column      :last_activity_at, :bigint
  column      :membership, TEXT, default: "join", null: false
  column      :name, TEXT
  column      :pinned, :blob, default: Sequel.lit("'[]'"), null: false
  column      :power_levels, :blob, default: Sequel.lit("'{}'"), null: false
  column      :preview, :text
  column      :preview_sender, TEXT
  column      :room_id, TEXT, null: false
  column      :space, :boolean, default: false, null: false
  column      :topic, :text
  column      :unread_count, :integer, default: 0, null: false
  column      :updated_at, TIMESTAMP, null: false

  #
  # Everything below is a field of matrix-sdk-base's RoomInfo that had
  # no column here. RoomInfo is ONE serialized blob in the SDK's
  # state_store (`room_info.data`), so the SDK pays nothing for having
  # 22 more fields than this table did; we store columns, so each one
  # has to be named. They are columns rather than a `room_info` jsonb
  # because the sidebar sorts and filters on most of them, and the
  # Inertia pages select columns.
  #
  # NOTE ON `membership`: RoomState has five values (Joined, Left,
  # Invited, Knocked, Banned) and this column was documented as
  # join/invite/leave. Knocked and Banned are now expected values; no
  # schema change, but it is not a three-way any more.

  # m.room.canonical_alias. `alt_aliases` is the published set.
  column      :canonical_alias, TEXT
  column      :alt_aliases, :blob, default: Sequel.lit("'[]'"), null: false

  # m.room.create, unpacked. `space` already covers create.type, but the
  # rest of that event was being discarded -- including the predecessor
  # link, without which an upgraded room's history is unreachable.
  column      :room_version, TEXT
  column      :creator, TEXT
  column      :federated, :boolean, default: true, null: false
  column      :predecessor_room_id, TEXT

  # m.room.tombstone. The successor side of the same chain.
  column      :tombstoned, :boolean, default: false, null: false
  column      :successor_room_id, TEXT

  # m.room.join_rules / m.room.guest_access / m.room.history_visibility.
  # `join_rule_allow` is the restricted-room allow list, which is part of
  # the join rule rather than a separate event.
  column      :join_rule, TEXT
  column      :join_rule_allow, :blob, default: Sequel.lit("'[]'"), null: false
  column      :guest_access, TEXT
  column      :history_visibility, TEXT

  # m.room.encryption, in full. `encrypted` is the boolean the UI reads;
  # this is the content it was derived from, and the rotation parameters
  # in it are what DeviceStore#outbound_session needs to decide when a
  # megolm session is stale.
  column      :encryption, :blob, default: Sequel.lit("'{}'"), null: false

  # RoomSummary: who the homeserver nominates to name the room, and the
  # counts it reports. The counts are NOT a count of matrix_room_members
  # -- that table holds the members we have synced, which for a large
  # room is a subset, and for an invite is a handful of stripped rows.
  column      :heroes, :blob, default: Sequel.lit("'[]'"), null: false
  column      :joined_member_count, :integer, default: 0, null: false
  column      :invited_member_count, :integer, default: 0, null: false

  # The computed name, which is not m.room.name. A room with no name is
  # named after its heroes ("Alice, Bob and 3 others"), and that string
  # depends on the member list, so it is cached rather than derived on
  # every render. `name` stays as the literal m.room.name.
  column      :display_name, TEXT

  # m.tag, which is what makes the sidebar's Favorite and Low priority
  # sections possible. Booleans for the two the spec names, because the
  # sidebar filters on them; the raw content too, because it carries the
  # per-tag `order` the sections sort by.
  column      :favourite, :boolean, default: false, null: false
  column      :low_priority, :boolean, default: false, null: false
  column      :tags, :blob, default: Sequel.lit("'{}'"), null: false

  # Manually marked unread, and which account-data event said so -- the
  # spec'd m.marked_unread and the older com.famedly.marked_unread are
  # both in the wild, and a client that cannot tell them apart will
  # fight itself over which to write back.
  column      :marked_unread, :boolean, default: false, null: false
  column      :marked_unread_source, TEXT

  # m.fully_read: the read MARKER, which is a different thing from the
  # read receipt and from the unread count. It is what positions the
  # "new messages" divider.
  column      :fully_read_event_id, TEXT

  # Per-room push rule override, cached. Global/All/MentionsOnly/Mute.
  column      :notification_mode, TEXT

  # The client-computed unread triple. DISTINCT FROM unread_count and
  # highlight_count, which are the server's own
  # `unread_notifications` -- the server counts by its push rules, the
  # client counts from the read receipt forward, and they disagree
  # routinely. Both are kept because the UI needs the client's numbers
  # and the sync protocol only gives the server's.
  column      :num_unread, :integer, default: 0, null: false
  column      :num_notifications, :integer, default: 0, null: false
  column      :num_mentions, :integer, default: 0, null: false
  column      :latest_receipt_event_id, TEXT

  # THE BACK-PAGINATION TOKEN, and the sync completeness flags that say
  # how much of this room we actually hold. `prev_batch` is the cursor
  # /messages has to be called with to reach anything older than the
  # oldest row in matrix_events; without it, stored history can only
  # ever grow forward and the gap behind it is permanent.
  column      :prev_batch, TEXT
  column      :sync_info, TEXT, default: "no_state", null: false
  column      :members_synced, :boolean, default: false, null: false
  column      :encryption_state_synced, :boolean, default: false, null: false

  # Who invited us. Only set while membership is "invite", and not
  # derivable afterwards -- the stripped invite state is the only place
  # it appears, and it is gone once the invite is accepted.
  column      :invited_by, TEXT

  # Whether this room's keys have all been pulled from the server-side
  # backup, so restore can resume rather than restart.
  column      :key_backup_fully_downloaded, :boolean, default: false, null: false

  # m.room.retention, m.room.member_hints and the MSC3401 call member
  # events. Kept as content because nothing filters on them; dropped
  # entirely they would have to be re-fetched from /state.
  column      :retention, :blob, default: Sequel.lit("'{}'"), null: false
  column      :member_hints, :blob, default: Sequel.lit("'{}'"), null: false
  column      :rtc_members, :blob, default: Sequel.lit("'{}'"), null: false

  index :last_activity_at, name: :index_matrix_rooms_on_last_activity_at
  index :room_id, unique: true, name: :index_matrix_rooms_on_room_id

end

