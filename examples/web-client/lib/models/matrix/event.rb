# frozen_string_literal: true

require "sequel/model"

require_relative "jsonb"
require_relative "typecasting"

module Models
  module Matrix
    class Event < Sequel::Model(:matrix_events)
      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend JSONB
      extend Typecasting

      jsonb :content, :raw, :unsigned, :push_actions

      # msgtypes whose content carries a file. m.sticker is its own event type.
      MEDIA_MSGTYPES = %w[m.image m.video m.audio m.file].freeze

      def validate
        super
        validates_presence :event_id
        validates_presence %i[room_id sender type]
        validates_unique %i[user_id event_id]
      end

      dataset_module do
        def in_room(room_id) = where(room_id: room_id)
        def chronological    = order(:origin_server_ts)
        def undecryptable    = exclude(decryption_error: nil)

        # Thread replies hang off a root; the main timeline excludes them.
        def in_thread(root_id) = where(thread_root_id: root_id)
        def main_timeline      = where(thread_root_id: nil)
      end

      def media_event?
        if redacted? || !decryption_error.to_s.empty?
          false
        else
          if type == "m.sticker"
            !media_mxc.nil?
          else
            type == "m.room.message" && MEDIA_MSGTYPES.include?(content["msgtype"]) && !media_mxc.nil?
          end
        end
      end

      def redacted? = !!redacted

      def media_mxc              = presence(content["url"])
      def thumbnail_mxc          = presence(content.dig("info", "thumbnail_url"))
      def media_content_type     = presence(content.dig("info", "mimetype"))
      def thumbnail_content_type = presence(content.dig("info", "thumbnail_info", "mimetype"))

      def media_filename
        name = content["body"].to_s.strip.tr("/\\", "-").sub(/\A\.+/, "").strip
        if name.empty?
          name = "attachment"
        end
        if File.extname(name).empty?
          ext = Marcel::TYPE_EXTS[media_content_type.to_s]&.first
          if ext
            "#{name}.#{ext}"
          else
            name
          end
        else
          name
        end
      end

      def preview_text
        if redacted?
          "Message deleted"
        else
          if decryption_error.to_s.empty?
            case type
            when "m.room.message" then truncate(content["body"].to_s, 120)
            when "m.reaction"     then "Reacted #{content.dig('m.relates_to', 'key')}"
            else type
            end
          else
            "Encrypted message"
          end
        end
      end

      private

        def presence(value)
          if value.to_s.empty?
            nil
          else
            value
          end
        end

        def truncate(string, length)
          if string.length <= length
            string
          else
            "#{string[0, length - 3]}..."
          end
        end
    end
  end
end

__END__

create_table?(:matrix_events) do
  primary_key :id, type: :Bignum, serial: true
  column      :content, :blob, default: Sequel.lit("jsonb('{}')"), null: false
  column      :created_at, TIMESTAMP, null: false
  column      :decryption_error, TEXT
  column      :edited_ts, :bigint
  column      :event_id, TEXT, null: false
  column      :origin_server_ts, :bigint, null: false
  column      :redacted, :boolean, default: false, null: false
  column      :reply_to_id, TEXT
  column      :room_id, TEXT, null: false
  column      :sender, TEXT, null: false
  column      :sender_avatar_url, TEXT
  column      :sender_display_name, TEXT
  column      :thing_id, :bigint
  column      :thread_root_id, TEXT
  column      :type, TEXT, null: false
  column      :updated_at, TIMESTAMP, null: false
  column      :user_id, :bigint, null: false

  # ── Beyond the Rails schema ────────────────────────────────────────

  # STATE EVENTS BELONG IN THE TIMELINE TOO. matrix_room_state holds
  # CURRENT state -- one row per (room, type, state_key) -- but a state
  # event is also a timeline entry that has to render in order ("Alice
  # changed the topic"), and the two are not the same row: state keeps
  # the latest, the timeline keeps every one. Without this column the
  # projection had to choose, and chose to drop them (Sync#apply_timeline
  # folds them into matrix_rooms and writes no event).
  column      :state_key, TEXT

  # THE RELATION, HOISTED OUT OF content SO IT CAN BE INDEXED. The
  # projection only ever read `m.thread` and `m.in_reply_to`, which left
  # `m.annotation` (reactions) and `m.replace` (edits) addressable only
  # by scanning content jsonb. The event cache store indexes exactly
  # these two columns, for exactly this reason.
  #
  # It also fixes ordering: an edit or redaction that arrives BEFORE its
  # target can be parked and replayed when the target lands, which
  # `apply_edit`/`apply_redaction` currently cannot do -- they look the
  # target up, find nothing, and drop the relation on the floor.
  column      :relates_to_id, TEXT
  column      :rel_type, TEXT

  # Which megolm session decrypted this, so a late room key can be
  # matched to the events it unlocks without re-deriving it from the
  # envelope (which the envelope no longer has -- see `raw`).
  column      :session_id, TEXT

  # THE EVENT AS IT ARRIVED. `content` is the decrypted inner content
  # only, so everything outside it was being thrown away: the envelope,
  # the signatures, `unsigned.redacted_because`, the whole "view source"
  # affordance every client has. TimelineEvent keeps the raw
  # `AnySyncTimelineEvent` for all three of its kinds, including the
  # undecryptable one -- which is also the only way a message that
  # failed to decrypt can be retried once the key shows up.
  column      :raw, :blob
  column      :unsigned, :blob, default: Sequel.lit("jsonb('{}')"), null: false

  # What the push rules decided for this event, evaluated once on the
  # way in. Per-event highlight is not derivable later: it depends on the
  # rules AS THEY WERE, plus the display name as it was.
  column      :push_actions, :blob, default: Sequel.lit("jsonb('[]')"), null: false

  # Local echo. Set when we enqueued the send, cleared when the
  # homeserver echoes the event back with a real event_id.
  column      :transaction_id, TEXT

  index :thing_id, name: :index_matrix_events_on_thing_id
  index %i[user_id event_id],
    unique: true,
    name:   :index_matrix_events_on_user_id_and_event_id
  # The aggregation lookup: every reaction, edit and annotation of one
  # event, which is the query the timeline runs per row.
  index %i[user_id room_id relates_to_id rel_type],
    name: :index_matrix_events_on_user_id_and_room_id_and_relates_to_id
  index %i[user_id room_id state_key],
    name: :index_matrix_events_on_user_id_and_room_id_and_state_key
  index %i[user_id room_id origin_server_ts],
    name: :idx_on_user_id_room_id_origin_server_ts_d6ecf91668
  index %i[user_id thread_root_id],
    name: :index_matrix_events_on_user_id_and_thread_root_id
  index :user_id, name: :index_matrix_events_on_user_id
end

# The same columns again, for a database that already has this table -- an
# import of the Rails app's ten. create_table? above is a no-op there, so
# without this not one of them would ever be created. See
# Migrations.added_columns.
added_columns(
  [:state_key, TEXT, {}],
  [:relates_to_id, TEXT, {}],
  [:rel_type, TEXT, {}],
  [:session_id, TEXT, {}],
  [:raw, :blob, {}],
  [:unsigned, :blob, {default: Sequel.lit("jsonb('{}')"), null: false}],
  [:push_actions, :blob, {default: Sequel.lit("jsonb('[]')"), null: false}],
  [:transaction_id, TEXT, {}],
)

added_indexes(
  [
    %i[user_id room_id relates_to_id rel_type],
    :index_matrix_events_on_user_id_and_room_id_and_relates_to_id,
  ],
  [
    %i[user_id room_id state_key],
    :index_matrix_events_on_user_id_and_room_id_and_state_key,
  ],
)
