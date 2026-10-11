# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the keys a server publishes for itself, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::KeysServer}.
          module KeysServer
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

            # v1.6 dropped the deprecated key ID from the path.
            module V1_6
              def self.included(base)
                # The key ID segment is gone at this version, so the bare `/server` route is what has to answer.
                base.it "can getServerKey without a key ID segment" do
                  published = unauthenticated.keys_server.get_server_key

                  expect(published.server_name).to be == server_name
                end
              end
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

            # v1.1 published the keys a server signs with.
            module V1_1
              def self.included(base)
                base.it "can getServerKey" do
                  published = unauthenticated.keys_server.get_server_key

                  expect(published.server_name).to be == server_name
                  expect(published.verify_keys).not.to be(:empty?)
                  expect(published.valid_until_ts).to be > 0
                end

                # The suite signs as this server, so the key it signs with is the key the server publishes.
                base.it "publishes the key the suite signs with" do
                  expect(unauthenticated.keys_server.get_server_key.verify_key(key.id)).to be == key.public_key
                end

                # The document is signed by the keys it publishes, which is what makes it worth anything.
                base.it "signs itself with the keys it publishes" do
                  expect(unauthenticated.keys_server.get_server_key.signatures).to be(:key?, server_name.to_sym)
                end

                # No authentication: a key is what a server fetches before it can sign anything.
                base.it "answers without a signature" do
                  expect(unauthenticated.keys_server.get_server_key.server_name).not.to be_nil
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("server keys cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if KeysServer.const_defined?(name, false)
                  include KeysServer.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
