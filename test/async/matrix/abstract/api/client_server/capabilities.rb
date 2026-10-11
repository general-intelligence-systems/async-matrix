# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the capabilities operation, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          module Capabilities
            # No changes in v1.19.
            module V1_19
            end

            # v1.18 added account moderation and forced forgetting.
            module V1_18
              def self.included(base)
                base.it "reads nothing for a capability the homeserver does not advertise" do
                  capabilities = client.get_capabilities

                  expect(capabilities).not.to be(:advertised?, "m.account_moderation")
                  expect(capabilities.suspend_accounts?).to be_nil
                  expect(capabilities.lock_accounts?).to be_nil
                  expect(capabilities.forget_forced_upon_leave?).to be_nil
                end
              end
            end

            # No changes in v1.17.
            module V1_17
            end

            # v1.16 added the profile fields capability.
            module V1_16
              def self.included(base)
                base.it "reads whether extended profile fields may be written" do
                  expect(client.get_capabilities.profile_fields?).to be == true
                end

                # The homeserver names neither list, which means every field is writable.
                base.it "reads nothing for a list of fields the homeserver did not name" do
                  capabilities = client.get_capabilities

                  expect(capabilities.allowed_profile_fields).to be_nil
                  expect(capabilities.disallowed_profile_fields).to be_nil
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

            # v1.12 added four capabilities about this user's own account.
            module V1_12
              def self.included(base)
                base.it "reads what this user may change about their own account" do
                  capabilities = client.get_capabilities

                  expect(capabilities.set_displayname?).to be == true
                  expect(capabilities.set_avatar_url?).to be == true
                  expect(capabilities.third_party_identifier_changes?).to be == true
                end

                # Advertised and disabled is not the same as not advertised, and this homeserver advertises it off.
                base.it "tells a disabled capability from an absent one" do
                  capabilities = client.get_capabilities

                  expect(capabilities).to be(:advertised?, "m.get_login_token")
                  expect(capabilities.get_login_token?).to be == false
                end
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

            # v1.1 is the oldest version, and capabilities already exist.
            module V1_1
              def self.included(base)
                base.it "can getCapabilities" do
                  expect(client.get_capabilities.capabilities).to be_a(Hash)
                end

                base.it "reads whether this user may change their password" do
                  expect(client.get_capabilities.change_password?).to be == true
                end

                base.it "reads the room version new rooms are created with" do
                  capabilities = client.get_capabilities

                  expect(capabilities.default_room_version).to be_a(String)
                  expect(capabilities).to be(:stable_room_version?, capabilities.default_room_version)
                end

                base.it "reads the stability of every room version the homeserver supports" do
                  available = client.get_capabilities.available_room_versions

                  expect(available).not.to be(:empty?)
                  expect(available.values.uniq - ["stable", "unstable"]).to be(:empty?)
                end

                # The response is an open map, so a capability this library has never heard of is still readable.
                base.it "reads a capability outside the specification's own namespace" do
                  unstable = client.get_capabilities.capabilities.keys.find{|name| name.to_s.start_with?("org.matrix.")}

                  expect(unstable).not.to be_nil
                  expect(client.get_capabilities[unstable]).to be_a(Hash)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("capabilities cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Capabilities.const_defined?(name, false)
                  include Capabilities.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
