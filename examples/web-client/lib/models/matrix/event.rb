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

      # The rel_types `rel_type` carries, which is the whole of what this table
      # knows about relations -- the SDK indexes exactly these two columns.
      THREAD     = "m.thread"
      REPLACE    = "m.replace"
      ANNOTATION = "m.annotation"
      REFERENCE  = "m.reference"

      # The relations that are folded into their target rather than rendered in
      # their own right. m.reference is not one: a reference is its own message.
      AGGREGATIONS = [THREAD, REPLACE, ANNOTATION].freeze

      def validate
        super
        validates_presence :event_id
        validates_presence %i[room_id sender type]
        validates_unique :event_id
      end

      dataset_module do
        def in_room(room_id) = where(room_id: room_id)
        def chronological    = order(:origin_server_ts)
        def undecryptable    = exclude(decryption_error: nil)

        # A thread reply is an event whose relation is m.thread, which is what
        # `relates_to_id` and `rel_type` already say. There is no thread_root_id
        # column because the SDK's events table has no such field -- the
        # relation IS the thread, and matrix_timeline_chunks is where a thread
        # gets a timeline of its own.
        def in_thread(root_id) = where(relates_to_id: root_id, rel_type: THREAD)

        # The room's own timeline: no thread replies, and no aggregations.
        #
        # A REACTION AND AN EDIT ARE NOT TIMELINE ROWS. They are folded into the
        # event they relate to -- #reactions and #edited? are how -- so a
        # timeline that also listed them would show each one twice, once as
        # itself and once on its target.
        #
        # It has to say "or null" out loud. `rel_type` is null on every event
        # that is not a relation at all, and `rel_type NOT IN (...)` is NULL
        # rather than true for those -- so a plain exclude() would hide the
        # entire timeline, which is the one thing this exists to show.
        def main_timeline
          where(rel_type: nil).or(Sequel.~(rel_type: AGGREGATIONS))
        end
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

      # Edited if anything relates to it with m.replace. There is no edited_ts
      # column: an edit is its own event, and the relation is what says so.
      def edited?
        self.class.where(relates_to_id: event_id, rel_type: REPLACE).any?
      end

      # m.in_reply_to, which lives inside the relation rather than beside it --
      # a reply is not one of the rel_types.
      def reply_to_id = content.dig("m.relates_to", "m.in_reply_to", "event_id")

      def formatted_body = presence(content["formatted_body"])

      # Who sent it, as the room knows them. The member row carries the
      # per-room display name and avatar; the global profile is the fallback for
      # somebody who has since left.
      def sender_member
        RoomMember.first(room_id: room_id, member_id: sender)
      end

      def sender_profile
        GlobalProfile.first(matrix_user_id: sender)
      end

      def sender_name
        sender_member&.name || sender_profile&.display_name || sender
      end

      def sender_avatar_url
        sender_member&.avatar_url || sender_profile&.avatar_url
      end

      # Reactions to this event, one row per distinct key, with whether
      # +member_id+ is among the people who sent it.
      def reactions(member_id = nil)
        self.class
          .where(relates_to_id: event_id, rel_type: ANNOTATION)
          .all
          .group_by{|event| event.content.dig("m.relates_to", "key")}
          .reject{|key, _| key.nil?}
          .map do |key, events|
            {
              key:   key,
              count: events.size,
              mine:  events.any?{|event| event.sender == member_id},
            }
          end
      end

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
  column      :content, :blob, default: Sequel.lit("'{}'"), null: false
  column      :created_at, TIMESTAMP, null: false
  column      :decryption_error, TEXT
  column      :event_id, TEXT, null: false
  column      :origin_server_ts, :bigint, null: false
  column      :redacted, :boolean, default: false, null: false
  column      :room_id, TEXT, null: false
  column      :sender, TEXT, null: false
  column      :type, TEXT, null: false
  column      :updated_at, TIMESTAMP, null: false

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
  column      :unsigned, :blob, default: Sequel.lit("'{}'"), null: false

  # What the push rules decided for this event, evaluated once on the
  # way in. Per-event highlight is not derivable later: it depends on the
  # rules AS THEY WERE, plus the display name as it was.
  column      :push_actions, :blob, default: Sequel.lit("'[]'"), null: false


  index :event_id, unique: true, name: :index_matrix_events_on_event_id
  # The aggregation lookup: every reaction, edit and annotation of one
  # event, which is the query the timeline runs per row.
  index %i[room_id relates_to_id rel_type],
    name:   :index_matrix_events_on_room_id_and_relates_to_id_and_rel_type
  index %i[room_id state_key], name: :index_matrix_events_on_room_id_and_state_key
  index %i[room_id origin_server_ts], name: :index_matrix_events_on_room_id_and_origin_server_ts

end

