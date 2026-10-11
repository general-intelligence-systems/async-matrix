# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "versions"

require_relative "events/readers"
require_relative "events/content"
require_relative "events/envelope"
require_relative "events/fields"
require_relative "events/registry"

require_relative "events/accepted_terms"
require_relative "events/call_answer"
require_relative "events/call_candidates"
require_relative "events/call_hangup"
require_relative "events/call_invite"
require_relative "events/call_negotiate"
require_relative "events/call_reject"
require_relative "events/call_sdp_stream_metadata_changed"
require_relative "events/call_select_answer"
require_relative "events/direct"
require_relative "events/dummy"
require_relative "events/forwarded_room_key"
require_relative "events/fully_read"
require_relative "events/identity_server"
require_relative "events/ignored_user_list"
require_relative "events/image_pack_rooms"
require_relative "events/invite_permission_config"
require_relative "events/key_backup"
require_relative "events/key_verification_accept"
require_relative "events/key_verification_cancel"
require_relative "events/key_verification_done"
require_relative "events/key_verification_key"
require_relative "events/key_verification_m_relates_to"
require_relative "events/key_verification_mac"
require_relative "events/key_verification_ready"
require_relative "events/key_verification_request"
require_relative "events/key_verification_start"
require_relative "events/marked_unread"
require_relative "events/policy_rule_room"
require_relative "events/policy_rule_server"
require_relative "events/policy_rule_user"
require_relative "events/presence"
require_relative "events/push_rules"
require_relative "events/reaction"
require_relative "events/receipt"
require_relative "events/recent_emoji"
require_relative "events/room_avatar"
require_relative "events/room_canonical_alias"
require_relative "events/room_create"
require_relative "events/room_encrypted"
require_relative "events/room_encryption"
require_relative "events/room_guest_access"
require_relative "events/room_history_visibility"
require_relative "events/room_image_pack"
require_relative "events/room_join_rules"
require_relative "events/room_key"
require_relative "events/room_key_bundle"
require_relative "events/room_key_request"
require_relative "events/room_key_withheld"
require_relative "events/room_member"
require_relative "events/room_message"
require_relative "events/room_message_feedback"
require_relative "events/room_name"
require_relative "events/room_pinned_events"
require_relative "events/room_policy"
require_relative "events/room_power_levels"
require_relative "events/room_redaction"
require_relative "events/room_server_acl"
require_relative "events/room_third_party_invite"
require_relative "events/room_tombstone"
require_relative "events/room_topic"
require_relative "events/secret_request"
require_relative "events/secret_send"
require_relative "events/space_child"
require_relative "events/space_parent"
require_relative "events/sticker"
require_relative "events/tag"
require_relative "events/typing"

module Async
  module Matrix
    # The values a representation carries, not the resources it describes.
    module Events
      class << self
        # The events built for a given specification version.
        #
        # @parameter version [String | Symbol] e.g. `"v1.19"`.
        # @returns [Module] the generated events.
        def [](version)
          Versions[version, self]
        end

        # The registry for a version, which maps an event onto the class describing it.
        #
        # An unversioned caller gets the unversioned classes, which carry every field the latest version describes.
        #
        # @parameter version [String | Symbol | nil] e.g. `"v1.19"`.
        # @returns [Registry] the registry.
        def registry(version = nil)
          if version
            Registry.for(self[version])
          else
            Registry.for(self)
          end
        end
      end
    end
  end
end
