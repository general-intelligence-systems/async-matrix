# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the list of threads, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::ThreadsList}.
          module ThreadsList
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

            # v1.4 added the list of threads.
            module V1_4
              def self.included(base)
                # A thread is an event which another event relates to by `m.thread`.
                base.let(:root){room.send_message("m.room.message", {msgtype: "m.text", body: "the root of a thread"})}

                base.let(:reply) do
                  room.send_message("m.room.message", {msgtype: "m.text", body: "in the thread", "m.relates_to": {rel_type: "m.thread", event_id: root.event_id}})
                end

                base.it "can getThreadRoots" do
                  reply

                  threads = client.threads_list.get_thread_roots(room.id)

                  expect(threads.chunk.map{|event| event[:event_id]}).to be(:include?, root.event_id)
                end

                base.it "has no threads in a room where nobody started one" do
                  expect(client.threads_list.get_thread_roots(room.id)).to be(:empty?)
                end
              end
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
            # The cases required at the version under test.
            CASES = Sus::Shared("threads cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if ThreadsList.const_defined?(name, false)
                  include ThreadsList.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
