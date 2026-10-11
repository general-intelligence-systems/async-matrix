# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the events pushed from one server to another, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::Transactions}.
          module Transactions
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

            # v1.1 pushed events from one server to another.
            module V1_1
              def self.included(base)
                base.let(:transaction_id){"txn-#{SecureRandom.hex(8)}"}

                # A transaction carrying nothing is still a transaction, and is the one the suite can send: an event pushed from this server to itself is an event it already has.
                base.it "can sendTransaction" do
                  expect(server.transactions.send_transaction(transaction_id, [], origin: server_name).pdus).to be_a(Hash)
                end

                base.it "accepts a transaction which carries nothing" do
                  expect(server.transactions.send_transaction(transaction_id, [], origin: server_name)).to be(:accepted?)
                end

                # Ephemeral data is not persisted, so a typing notification is accepted and forgotten.
                base.it "carries ephemeral data alongside the events" do
                  edu = {edu_type: "m.typing", content: {room_id: room.id, user_id: user_id, typing: false}}

                  expect(server.transactions.send_transaction(transaction_id, [], origin: server_name, edus: [edu])).to be(:accepted?)
                end

                base.it "names when it was sent" do
                  sent = (Time.now.to_f * 1000).to_i

                  expect(server.transactions.send_transaction(transaction_id, [], origin: server_name, origin_server_ts: sent)).to be(:accepted?)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("transactions cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Transactions.const_defined?(name, false)
                  include Transactions.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
