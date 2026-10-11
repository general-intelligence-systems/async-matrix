# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the encryption keys of a user, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::UserKeys}.
          module UserKeys
            # No changes in v1.19.
            module V1_19
            end

            # No changes in v1.18.
            module V1_18
            end

            # No changes in v1.17.
            module V1_17
            end

            # No changes in v1.16.
            module V1_16
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

            # v1.1 queried and claimed another server's keys.
            module V1_1
              def self.included(base)
                base.let(:member){client.get_token_owner.user_id}

                base.let(:device){client.get_token_owner.device_id}

                # An empty list asks for every device the user has.
                base.it "can queryUserEncryptionKeys" do
                  expect(server.user_keys.query_user_encryption_keys({member => []}).device_keys).to be(:key?, member.to_sym)
                end

                base.it "reads the devices of one user" do
                  expect(server.user_keys.query_user_encryption_keys({member => []}).devices_of(member)).to be_a(Hash)
                end

                # The device has published no one time keys, so there is nothing to hand over - which is an empty answer rather than a refusal.
                base.it "can claimUserEncryptionKeys" do
                  claimed = server.user_keys.claim_user_encryption_keys({member => {device => "signed_curve25519"}})

                  expect(claimed.one_time_keys).to be_a(Hash)
                end

                base.it "hands over nothing where the device published nothing" do
                  expect(server.user_keys.claim_user_encryption_keys({member => {device => "signed_curve25519"}})).to be(:empty?)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("user keys cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if UserKeys.const_defined?(name, false)
                  include UserKeys.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
