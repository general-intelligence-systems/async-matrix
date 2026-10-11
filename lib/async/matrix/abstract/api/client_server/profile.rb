# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::Profile}.
        module Profile
          # No changes in v1.19.
          module V1_19
          end

          # No changes in v1.18.
          module V1_18
          end

          # No changes in v1.17.
          module V1_17
          end

          # v1.16 replaced the named fields with one field by key.
          module V1_16
            extend Removals

            removed :get_display_name, use: :get_profile_field

            removed :set_display_name, use: :set_profile_field

            removed :get_avatar_url, use: :get_profile_field

            removed :set_avatar_url, use: :set_profile_field

            # One field of a user's profile.
            #
            # @parameter user_id [String] the user to ask about.
            # @parameter key [String] the field, e.g. `displayname` or `m.tz`.
            # @returns [ProfileField] the field, which carries its value.
            def get_profile_field(user_id, key)
              api::ProfileField.get(@resource.with(path: self.path_for(user_id, key)))
            end

            # Set one field of this user's profile.
            #
            # @parameter user_id [String] the user whose profile it is.
            # @parameter key [String] the field to set.
            # @parameter value [Object] what to set it to, which the specification shapes per field.
            # @returns [Representation] the homeserver's acknowledgement.
            def set_profile_field(user_id, key, value)
              api::Representation.put(@resource.with(path: self.path_for(user_id, key)), {key.to_sym => value})
            end

            # Delete one field of this user's profile.
            #
            # @parameter user_id [String] the user whose profile it is.
            # @parameter key [String] the field to delete.
            # @returns [Representation] the homeserver's acknowledgement.
            def delete_profile_field(user_id, key)
              api::Representation.delete(@resource.with(path: self.path_for(user_id, key)))
            end

            # @parameter user_id [String] the user whose profile it is.
            # @parameter key [String] the field.
            # @returns [String] the path of that field.
            def path_for(user_id, key)
              "#{self.class.path_for(user_id)}/#{::Protocol::URL::Encoding.escape(key)}"
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

          # No changes in v1.12.
          module V1_12
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

          # v1.1 named the display name and the avatar.
          module V1_1
            # The name a user is shown as.
            #
            # @parameter user_id [String] the user to ask about.
            # @returns [UserProfile] the profile, carrying the name alone.
            def get_display_name(user_id)
              api::UserProfile.get(@resource.with(path: "#{self.class.path_for(user_id)}/displayname"))
            end

            # Set the name this user is shown as.
            #
            # @parameter user_id [String] the user whose name it is.
            # @parameter displayname [String] the name to be shown as.
            # @returns [Representation] the homeserver's acknowledgement.
            def set_display_name(user_id, displayname)
              api::Representation.put(@resource.with(path: "#{self.class.path_for(user_id)}/displayname"), {displayname: displayname})
            end

            # The avatar a user is shown with.
            #
            # @parameter user_id [String] the user to ask about.
            # @returns [UserProfile] the profile, carrying the avatar alone.
            def get_avatar_url(user_id)
              api::UserProfile.get(@resource.with(path: "#{self.class.path_for(user_id)}/avatar_url"))
            end

            # Set the avatar this user is shown with.
            #
            # @parameter user_id [String] the user whose avatar it is.
            # @parameter avatar_url [String] the `mxc://` URI of the avatar.
            # @returns [Representation] the homeserver's acknowledgement.
            def set_avatar_url(user_id, avatar_url)
              api::Representation.put(@resource.with(path: "#{self.class.path_for(user_id)}/avatar_url"), {avatar_url: avatar_url})
            end
          end
        end

        # Layers for {ruby Async::Matrix::ClientServer::ProfileField}.
        module ProfileField
          # No changes in v1.19.
          module V1_19
          end

          # No changes in v1.18.
          module V1_18
          end

          # No changes in v1.17.
          module V1_17
          end

          # v1.16 added the field endpoints, whose response carries the field.
          module V1_16
            # The value of the field which was asked for.
            #
            # Reading it needs the key again.
            #
            # @parameter key [String] the field which was asked for.
            # @returns [Object | nil] its value.
            def value_of(key)
              self.value[key.to_sym]
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

          # No changes in v1.12.
          module V1_12
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

          # No changes in v1.1.
          module V1_1
          end
        end
      end
    end
  end
end
