# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::Capabilities}.
        module Capabilities
          # No changes in v1.19.
          module V1_19
          end

          # v1.18 added account moderation and forced forgetting.
          module V1_18
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

          # No changes in v1.17.
          module V1_17
          end

          # v1.16 added the profile fields capability.
          module V1_16
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

            # The fields this user may not write, which means nothing if {#allowed_profile_fields} named any.
            #
            # @returns [Array(String) | nil] the fields, or nil if it named none.
            def disallowed_profile_fields
              self["m.profile_fields"]&.fetch(:disallowed, nil)
            end
          end

          # No changes in v1.15.
          module V1_15
          end

          # No changes in v1.14.
          module V1_14
          end

          # No changes in v1.13.
          module V1_13
          end

          # v1.12 added four capabilities about this user's own account.
          module V1_12
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
          end

          # No changes in v1.11.
          module V1_11
          end

          # No changes in v1.10.
          module V1_10
          end

          # No changes in v1.9.
          module V1_9
          end

          # No changes in v1.8.
          module V1_8
          end

          # No changes in v1.7.
          module V1_7
          end

          # No changes in v1.6.
          module V1_6
          end

          # No changes in v1.5.
          module V1_5
          end

          # No changes in v1.4.
          module V1_4
          end

          # No changes in v1.3.
          module V1_3
          end

          # No changes in v1.2.
          module V1_2
          end

          # v1.1 has the password and room version capabilities.
          module V1_1
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
          end
        end
      end
    end
  end
end
