# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::AccountDeactivation}.
        module AccountDeactivation
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

          # v1.15 took the deactivation from the registration.
          module V1_15
            # Deactivate this user's account, which cannot be undone.
            #
            # @parameter auth [Hash | nil] the user interactive authentication, without which the homeserver asks for it.
            # @parameter erase [Boolean | nil] whether to forget what the user sent, as far as the homeserver can.
            # @parameter id_server [String | nil] the identity server to unbind the addresses from.
            # @returns [UnbindResult] what the identity server did with the addresses.
            def deactivate_account(auth: nil, erase: nil, id_server: nil)
              payload = {auth: auth, erase: erase, id_server: id_server}.compact

              api::UnbindResult.post(@resource.with(path: "#{V3}/account/deactivate"), payload)
            end
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

          # No changes in v1.1.
          module V1_1
          end
        end
      end
    end
  end
end
