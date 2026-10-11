# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/room_message"

module Async
  module Matrix
    module Events
      class Message < Content
        class << self
          def event_type = "m.room.message"

          def framing = :room_event
        end

        def body = @value[:body]

        def msgtype = @value[:msgtype]
      end

      class TextMessage < Message
        class << self
          def variant = {msgtype: "m.text"}
        end

        include Captions
      end

      class EmoteMessage < Message
        class << self
          def variant = {msgtype: "m.emote"}
        end

        include Captions
      end

      class NoticeMessage < Message
        class << self
          def variant = {msgtype: "m.notice"}
        end

        include Captions
      end

      class FileMessage < Message
        class << self
          def variant = {msgtype: "m.file"}
        end

        include Attachment
        include Filename
      end

      class ImageMessage < Message
        class << self
          def variant = {msgtype: "m.image"}
        end

        include Attachment
      end

      class AudioMessage < Message
        class << self
          def variant = {msgtype: "m.audio"}
        end

        include Attachment
      end

      class VideoMessage < Message
        class << self
          def variant = {msgtype: "m.video"}
        end

        include Attachment
      end

      class LocationMessage < Message
        class << self
          def variant = {msgtype: "m.location"}
        end

        def geo_uri = @value[:geo_uri]

        def info = @value[:info]
      end

      class ServerNoticeMessage < Message
        class << self
          def variant = {msgtype: "m.server_notice"}
        end

        def server_notice_type = @value[:server_notice_type]

        def admin_contact = @value[:admin_contact]

        def limit_type = @value[:limit_type]
      end

      class KeyVerificationRequestMessage < Message
        class << self
          def variant = {msgtype: "m.key.verification.request"}
        end

        include Captions

        def from_device = @value[:from_device]

        def verification_methods = @value[:methods]

        def to = @value[:to]
      end
    end
  end
end