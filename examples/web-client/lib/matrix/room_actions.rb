# frozen_string_literal: true

require "securerandom"

require_relative "session"

module Matrix
  module RoomActions
    PENDING = 0

    module_function

    def with_room(room_id)
      credential = Models::Matrix::Credential.first

      unless credential&.usable?
        raise Error, "not signed in"
      end

      Session.open(credential) do |client, _credentials|
        yield client, client.room(room_id), credential
      end
    end

    class Error < StandardError; end

    def enqueue!(room_id, type, content)
      transaction_id = SecureRandom.urlsafe_base64(16)

      Models::Matrix::SendQueue.new(
        room_id:        room_id,
        transaction_id: transaction_id,
        event_type:     type,
        content:        content,
        priority:       PENDING,
        enqueued_at:    (Time.now.to_f * 1000).to_i,
      ).save(validate: false)

      transaction_id
    end

    def dequeue!(room_id, transaction_id)
      Models::Matrix::SendQueue.where(room_id: room_id, transaction_id: transaction_id).delete
      Models::Matrix::SendQueueDependent.where(room_id: room_id, parent_transaction_id: transaction_id).delete
    end

    def wedge!(room_id, transaction_id, reason)
      Models::Matrix::SendQueue
        .where(room_id: room_id, transaction_id: transaction_id)
        .update(wedge_reason: reason.to_s)
    end

    def abort!(room_id, transaction_id)
      self.dequeue!(room_id, transaction_id)
    end

    def send_message(room_id, body, reply_to: nil, edits: nil)
      content = { "msgtype" => "m.text", "body" => body }

      unless reply_to.to_s.empty?
        content["m.relates_to"] = { "m.in_reply_to" => { "event_id" => reply_to } }
      end

      unless edits.to_s.empty?
        content["m.new_content"] = { "msgtype" => "m.text", "body" => body }
        content["m.relates_to"] = { "rel_type" => "m.replace", "event_id" => edits }
        content["body"] = "* #{body}"
      end

      self.send_event(room_id, "m.room.message", content)
    end

    def send_event(room_id, type, content)
      transaction_id = self.enqueue!(room_id, type, content)

      begin
        answer = self.with_room(room_id) do |_client, room, _credential|
          room.send_message(type, content, transaction_id: transaction_id)
        end

        self.dequeue!(room_id, transaction_id)

        answer
      rescue StandardError => error
        self.wedge!(room_id, transaction_id, error.message)

        raise
      end
    end

    def react(room_id, event_id, key)
      existing = Models::Matrix::Event.first(
        room_id: room_id, type: "m.reaction", relates_to_id: event_id,
      )

      if existing && existing.content.to_h.dig("m.relates_to", "key") == key
        self.redact(room_id, existing.event_id)
      else
        self.send_event(
          room_id,
          "m.reaction",
          { "m.relates_to" => { "rel_type" => "m.annotation", "event_id" => event_id, "key" => key } },
        )
      end
    end

    def redact(room_id, event_id, reason: nil)
      self.with_room(room_id) do |client, _room, _credential|
        client.redaction.redact_event(room_id, event_id, reason: reason)
      end
    end

    def report(room_id, event_id, reason: nil)
      self.with_room(room_id) do |client, _room, _credential|
        client.report_content.report_event(room_id, event_id, reason: reason)
      end
    end

    def invite(room_id, user_id, reason: nil)
      self.with_room(room_id) do |client, _room, _credential|
        client.inviting.invite_user(room_id, user_id, reason: reason)
      end
    end

    def kick(room_id, user_id, reason: nil)
      self.with_room(room_id) do |client, _room, _credential|
        client.kicking.kick(room_id, user_id, reason: reason)
      end
    end

    def ban(room_id, user_id, reason: nil)
      self.with_room(room_id) do |client, _room, _credential|
        client.banning.ban(room_id, user_id, reason: reason)
      end
    end

    def unban(room_id, user_id, reason: nil)
      self.with_room(room_id) do |client, _room, _credential|
        client.banning.unban(room_id, user_id, reason: reason)
      end
    end

    def join(room_id)
      self.with_room(room_id) do |_client, room, _credential|
        room.join_room_by_id
      end
    end

    def leave(room_id)
      self.with_room(room_id) do |_client, room, _credential|
        room.leave_room
      end
    end

    # Forgetting is the one action which deletes locally: the homeserver stops reporting the room,
    # so sync will never say it is gone.
    def forget(room_id)
      self.with_room(room_id) do |_client, room, _credential|
        room.leave_room
        room.forget_room
      end

      self.purge!(room_id)
    end

    def purge!(room_id)
      [
        Models::Matrix::Event, Models::Matrix::RoomState, Models::Matrix::RoomMember,
        Models::Matrix::AccountData, Models::Matrix::Receipt, Models::Matrix::ThreadSummary,
        Models::Matrix::TimelineChunk, Models::Matrix::SendQueue, Models::Matrix::MemberDisplayName,
      ].each do |model|
        model.where(room_id: room_id).delete
      end

      Models::Matrix::Room.where(room_id: room_id).delete
    end

    def set_state(room_id, type, content, state_key = "")
      self.with_room(room_id) do |_client, room, _credential|
        room.set_room_state_with_key(type, content, state_key)
      end
    end

    def set_name(room_id, name)
      self.set_state(room_id, "m.room.name", { "name" => name })
    end

    def set_topic(room_id, topic)
      self.set_state(room_id, "m.room.topic", { "topic" => topic })
    end

    def set_avatar(room_id, url)
      self.set_state(room_id, "m.room.avatar", { "url" => url })
    end

    def set_canonical_alias(room_id, canonical, alt_aliases = [])
      self.set_state(
        room_id,
        "m.room.canonical_alias",
        { "alias" => canonical, "alt_aliases" => alt_aliases }.compact,
      )
    end

    def set_join_rule(room_id, join_rule, allow = nil)
      content = { "join_rule" => join_rule }

      unless allow.nil?
        content["allow"] = allow
      end

      self.set_state(room_id, "m.room.join_rules", content)
    end

    def set_history_visibility(room_id, visibility)
      self.set_state(room_id, "m.room.history_visibility", { "history_visibility" => visibility })
    end

    def set_guest_access(room_id, access)
      self.set_state(room_id, "m.room.guest_access", { "guest_access" => access })
    end

    def enable_encryption(room_id)
      self.set_state(
        room_id,
        "m.room.encryption",
        { "algorithm" => "m.megolm.v1.aes-sha2" },
      )
    end

    # Power levels are one state event, so a change is read-modify-write over what is already there.
    def set_power_level(room_id, user_id, level)
      current = Models::Matrix::RoomState.content_for(room_id: room_id, event_type: "m.room.power_levels") || {}
      users = (current["users"] || {}).dup

      if level.nil?
        users.delete(user_id)
      else
        users[user_id] = level.to_i
      end

      self.set_state(room_id, "m.room.power_levels", current.merge("users" => users))
    end

    def upgrade(room_id, version)
      self.with_room(room_id) do |client, _room, _credential|
        client.room_upgrades.upgrade_room(room_id, version)
      end
    end

    def set_tag(room_id, tag, order: nil)
      self.with_room(room_id) do |client, _room, credential|
        client.tags.set_room_tag(credential.matrix_user_id, room_id, tag, order: order)
      end
    end

    def delete_tag(room_id, tag)
      self.with_room(room_id) do |client, _room, credential|
        client.tags.delete_room_tag(credential.matrix_user_id, room_id, tag)
      end
    end

    def set_category(room_id, category)
      {"favourite" => "m.favourite", "low_priority" => "m.lowpriority"}.each do |name, tag|
        if category == name
          self.set_tag(room_id, tag)
        else
          begin
            self.delete_tag(room_id, tag)
          rescue StandardError
            nil
          end
        end
      end
    end

    def set_room_account_data(room_id, type, content)
      self.with_room(room_id) do |client, _room, credential|
        client.account_data.set_account_data_per_room(credential.matrix_user_id, room_id, type, content)
      end
    end

    def mark_unread(room_id, unread)
      self.set_room_account_data(room_id, "m.marked_unread", { "unread" => unread })
    end

    def set_fully_read(room_id, event_id)
      self.set_room_account_data(room_id, "m.fully_read", { "event_id" => event_id })
    end

    def send_receipt(room_id, event_id, receipt_type: "m.read", thread_id: nil)
      self.with_room(room_id) do |client, _room, _credential|
        client.receipts.post_receipt(room_id, receipt_type, event_id, thread_id: thread_id)
      end
    end

    def set_typing(room_id, typing, timeout: 30_000)
      self.with_room(room_id) do |client, _room, credential|
        client.typing.set_typing(room_id, credential.matrix_user_id, typing, timeout: timeout)
      end
    end
  end
end
