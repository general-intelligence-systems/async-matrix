# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the profile operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::Profile}.
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
              def self.included(base)
                base.it "can setProfileField" do
                  expect(client.profile.set_profile_field(self.user_id, "displayname", "Alice").value).to be == {}
                end

                base.it "can getProfileField" do
                  client.profile.set_profile_field(self.user_id, "displayname", "Alice")

                  expect(client.profile.get_profile_field(self.user_id, "displayname").value_of("displayname")).to be == "Alice"
                end

                base.it "can deleteProfileField" do
                  client.profile.set_profile_field(self.user_id, "displayname", "Alice")

                  expect(client.profile.delete_profile_field(self.user_id, "displayname").value).to be == {}
                end

                # The methods the named fields were reached by are still here, and say what became of them.
                base.it "says the named fields were withdrawn" do
                  error = nil

                  begin
                    client.profile.get_display_name(self.user_id)
                  rescue Async::Matrix::RemovedOperationError => error
                  end

                  expect(error.version).to be == "v1.16"
                  expect(error.replacement).to be == :get_profile_field
                end
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
              # The operations these cases exercise are gone from v1.16, and so are the cases.
              WITHDRAWN_IN = "v1.16"

              def self.included(base)
                base.it "can setDisplayName" do
                  expect(client.profile.set_display_name(self.user_id, "Alice").value).to be == {}
                end

                base.it "can getDisplayName" do
                  client.profile.set_display_name(self.user_id, "Alice")

                  expect(client.profile.get_display_name(self.user_id).displayname).to be == "Alice"
                end

                base.it "can setAvatarUrl" do
                  expect(client.profile.set_avatar_url(self.user_id, "mxc://localhost/avatar").value).to be == {}
                end

                base.it "can getAvatarUrl" do
                  client.profile.set_avatar_url(self.user_id, "mxc://localhost/avatar")

                  expect(client.profile.get_avatar_url(self.user_id).avatar_url).to be == "mxc://localhost/avatar"
                end
              end
            end
            # The cases required at the version under test.
            #
            # A layer whose operations a later version withdrew names that version, and is left out once the version under test has reached it: the cases go the way the operations did.
            CASES = Sus::Shared("profile cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Profile.const_defined?(name, false)
                  layer = Profile.const_get(name, false)

                  if layer.const_defined?(:WITHDRAWN_IN, false) and Async::Matrix::Versions.up_to(Async::Matrix::TEST_VERSION).include?(layer::WITHDRAWN_IN)
                    next
                  end

                  include layer
                end
              end
            end
          end
        end
      end
    end
  end
end
