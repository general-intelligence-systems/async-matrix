# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::Transactions}.
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
            # Push events and ephemeral data to another server.
            #
            # A transaction is the one way a server is told about anything: everything else pulls.
            #
            # @parameter transaction_id [String] an ID of this sender's own, so the push can be repeated.
            # @parameter pdus [Array(Hash)] the room events, which are signed.
            # @parameter edus [Array(Hash) | nil] the ephemeral data, which is not persisted.
            # @parameter origin [String] the server sending it, which signs it too.
            # @parameter origin_server_ts [Integer | nil] when it was sent, in milliseconds since the epoch.
            # @returns [TransactionResult] what became of each event.
            def send_transaction(transaction_id, pdus, origin:, edus: nil, origin_server_ts: nil)
              path = "#{FEDERATION_V1}/send/#{::Protocol::URL::Encoding.escape(transaction_id)}"

              payload = {
                origin: origin,
                origin_server_ts: origin_server_ts || (Time.now.to_f * 1000).to_i,
                pdus: pdus,
              }

              api::TransactionResult.put(@resource.with(path: path), payload.merge({edus: edus}.compact))
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::TransactionResult}.
        module TransactionResult
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

          # v1.1 answered with what became of each event.
          module V1_1
            # An event which was rejected is reported here rather than by refusing the transaction.
            #
            # @returns [Hash] the outcome of each event, by event ID.
            def pdus
              self.value[:pdus] || {}
            end

            # @returns [Array(String)] the events which were rejected, by ID.
            def rejected
              self.pdus.filter_map do |event_id, outcome|
                if outcome[:error]
                  event_id.to_s
                else
                  nil
                end
              end
            end

            # @returns [Boolean] whether every event was accepted.
            def accepted?
              self.rejected.empty?
            end
          end
        end
      end
    end
  end
end
