# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the keys operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          module Keys
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

            # v1.7 removed the query token.
            module V1_7
              def self.included(base)
                base.it "refuses a query token" do
                  expect(client.keys.query_accepts_token?).to be == false

                  expect do
                    client.keys.query_keys({self.user_id => []}, token: "s0")
                  end.to raise_exception(ArgumentError)
                end
              end
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

            # v1.2 added fallback keys to the upload.
            module V1_2
              def self.included(base)
                base.it "uploads fallback keys" do
                  uploaded = client.keys.upload_keys(fallback_keys: {"signed_curve25519:AAAAAQ": {key: "key", fallback: true, signatures: {}}})

                  expect(uploaded.one_time_key_counts).to be_a(Hash)
                end
              end
            end

            # v1.1 is the oldest version, and carries every key case.
            module V1_1
              def self.included(base)
                base.it "can uploadKeys" do
                  uploaded = client.keys.upload_keys(one_time_keys: {"signed_curve25519:AAAAAQ": {key: "key", signatures: {}}})

                  expect(uploaded.count("signed_curve25519")).to be_a(Integer)
                end

                base.it "can queryKeys" do
                  expect(client.keys.query_keys({self.user_id => []}).failures).to be == {}
                end

                base.it "can claimKeys" do
                  claimed = client.keys.claim_keys({self.user_id => {client.get_token_owner.device_id => "signed_curve25519"}})

                  expect(claimed.failures).to be == {}
                end

                base.it "can getKeysChanges" do
                  token = client.sync(timeout: 0).next_batch

                  expect(client.keys.get_keys_changes(from: token, to: token).changed).to be_a(Array)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("keys cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Keys.const_defined?(name, false)
                  include Keys.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
