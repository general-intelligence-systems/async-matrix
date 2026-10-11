# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/capabilities"

module Async
  module Matrix
    module ClientServer
      # What the homeserver will let this user do.
      #
      # A capability the server does not advertise is absent rather than disabled, so a reader answers nil.
      class Capabilities < Representation
        include Versioned

        # @returns [Hash] every capability the homeserver advertised, by name.
        def capabilities
          self.value[:capabilities] || {}
        end

        # @parameter name [String] the capability, e.g. `m.change_password`.
        # @returns [Hash | nil] what the homeserver said about it, or nil.
        def [](name)
          self.capabilities[name.to_sym]
        end

        # Whether the homeserver advertised a capability at all.
        #
        # @parameter name [String] the capability.
        # @returns [Boolean] whether it was advertised.
        def advertised?(name)
          self.capabilities.key?(name.to_sym)
        end

        # Whether a capability is enabled.
        #
        # @parameter name [String] the capability.
        # @returns [Boolean | nil] whether it is enabled, or nil if it was not advertised.
        def enabled?(name)
          self[name]&.fetch(:enabled, nil)
        end

        # @returns [Boolean | nil] whether this user may change their password.
        def change_password?
          self.enabled?("m.change_password")
        end

        # @returns [Hash | nil] the room versions, as the homeserver described them.
        def room_versions
          self["m.room_versions"]
        end

        # @returns [String | nil] the room version new rooms are created with.
        def default_room_version
          self.room_versions&.fetch(:default, nil)
        end

        # The room versions the homeserver supports, each `stable` or `unstable`.
        #
        # @returns [Hash] the stability of each, by version.
        def available_room_versions
          self.room_versions&.fetch(:available, nil) || {}
        end

        # @parameter version [String] the room version, e.g. `11`.
        # @returns [Boolean] whether the homeserver calls it stable.
        def stable_room_version?(version)
          self.available_room_versions[version.to_s.to_sym] == "stable"
        end

        # @returns [Boolean | nil] whether this user may change their display name.
        def set_displayname?
          self.enabled?("m.set_displayname")
        end

        # @returns [Boolean | nil] whether this user may change their avatar.
        def set_avatar_url?
          self.enabled?("m.set_avatar_url")
        end

        # Whether this user may change the third party identifiers on their account.
        #
        # @returns [Boolean | nil] whether they may.
        def third_party_identifier_changes?
          self.enabled?("m.3pid_changes")
        end

        # Whether this user may generate a token to log another client in.
        #
        # @returns [Boolean | nil] whether they may.
        def get_login_token?
          self.enabled?("m.get_login_token")
        end

        # @returns [Boolean | nil] whether this user may set extended profile fields.
        def profile_fields?
          self.enabled?("m.profile_fields")
        end

        # The profile fields this user may write, if the homeserver named them.
        #
        # @returns [Array(String) | nil] the fields, or nil if it named none.
        def allowed_profile_fields
          self["m.profile_fields"]&.fetch(:allowed, nil)
        end

        # The profile fields this user may not write, which means nothing if {#allowed_profile_fields} named any.
        #
        # @returns [Array(String) | nil] the fields, or nil if it named none.
        def disallowed_profile_fields
          self["m.profile_fields"]&.fetch(:disallowed, nil)
        end

        # @returns [Boolean | nil] whether the homeserver forgets a room when this user leaves it.
        def forget_forced_upon_leave?
          self.enabled?("m.forget_forced_upon_leave")
        end

        # @returns [Boolean | nil] whether this user may suspend another.
        def suspend_accounts?
          self["m.account_moderation"]&.fetch(:suspend, nil)
        end

        # @returns [Boolean | nil] whether this user may lock another.
        def lock_accounts?
          self["m.account_moderation"]&.fetch(:lock, nil)
        end
      end
    end
  end
end
