# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# The cases for the sync operations, layered by specification version exactly as the
# implementation is: a case lives in the version which introduced the thing it exercises, and the
# version under test decides which layers apply. A case named `can <operationId>` is what
# {Async::Matrix::OperationsContext} requires, and it must reach the homeserver.
#
# `CASES` applies the layers up to the version under test, in the same ascending order the library
# uses, so the concrete test includes one thing rather than knowing about versions at all.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          module Sync
            # No changes in v1.19.
            module V1_19
            end

            # No changes in v1.18.
            module V1_18
            end

            # No changes in v1.17.
            module V1_17
            end

            # v1.16 added `use_state_after`, and the `state_after` field it asks the server to return in
            # place of `state`.
            module V1_16
              def self.included(base)
                base.it "asks for the state after the timeline" do
                  room

                  # The versioned class, reached through the client, so that the layer under test
                  # is the one which runs:
                  sync = client.api::Sync.start(client, timeout: 0, use_state_after: true)

                  expect(sync.state_after(room.id)).not.to be_nil
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

            # v1.4 added per-thread notification counts to each joined room.
            module V1_4
              def self.included(base)
                base.it "reports the unread counts per thread" do
                  room

                  sync = client.sync(timeout: 0)

                  # A room with no threads reports no counts, which is still the field being understood:
                  expect(sync.unread_thread_notifications(room.id)).to be_nil | be_a(Hash)
                end
              end
            end

            # No changes in v1.3.
            module V1_3
            end

            # No changes in v1.2.
            module V1_2
            end

            # v1.1 is the oldest version this library supports, and syncing already exists at it.
            module V1_1
              def self.included(base)
                base.it "can sync" do
                  expect(client.sync(timeout: 0).next_batch).to be_a(String)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("sync cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Sync.const_defined?(name, false)
                  include Sync.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
