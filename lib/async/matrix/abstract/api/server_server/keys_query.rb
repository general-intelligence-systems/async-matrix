# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::KeysQuery}.
        module KeysQuery
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

          # v1.1 asked a notary server for another's keys.
          module V1_1
            # The keys a notary server holds for another server.
            #
            # Asking a third party rather than the server itself is what makes it a notary.
            #
            # @parameter server_name [String] the server whose keys are wanted.
            # @parameter minimum_valid_until_ts [Integer | nil] the earliest expiry which will do.
            # @returns [QueriedKeys] the keys the notary vouches for.
            def perspectives_key_query(server_name, minimum_valid_until_ts: nil)
              path = "#{KEY_V2}/query/#{::Protocol::URL::Encoding.escape(server_name)}"
              parameters = {minimum_valid_until_ts: minimum_valid_until_ts}.compact

              api::QueriedKeys.get(@resource.with(path: path, parameters: parameters))
            end

            # The keys a notary holds for several servers, asked for at once.
            #
            # @parameter server_keys [Hash] the expiry wanted, by server name and key ID.
            # @returns [QueriedKeys] the keys the notary vouches for.
            def bulk_perspectives_key_query(server_keys)
              path = "#{KEY_V2}/query"

              api::QueriedKeys.post(@resource.with(path: path), {server_keys: server_keys})
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::QueriedKeys}.
        module QueriedKeys
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

          # v1.1 answered with a key document per server.
          module V1_1
            # Each document is signed by the server it describes and by the notary.
            #
            # @returns [Array(Hash)] the key documents.
            def server_keys
              self.value[:server_keys] || []
            end

            # @returns [Boolean] whether the notary vouches for nothing.
            def empty?
              self.server_keys.empty?
            end

            # The document for one server, where the notary has one.
            #
            # @parameter server_name [String] the server to read.
            # @returns [Hash | nil] its keys.
            def keys_of(server_name)
              self.server_keys.find{|document| document[:server_name] == server_name}
            end
          end
        end
      end
    end
  end
end
