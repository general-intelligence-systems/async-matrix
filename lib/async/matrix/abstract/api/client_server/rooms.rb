# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::Room}.
        module Room
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

          # v1.12 renamed `server_name` to `via`.
          module V1_12
            # @returns [Symbol] the parameter name.
            def join_via_parameter
              :via
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

          # v1.3 made the `from` token optional.
          module V1_3
            # @returns [Boolean] whether `from` is required.
            def pagination_requires_from?
              false
            end
          end

          # No changes in v1.2.
          module V1_2
          end

          # v1.1 carries what the later layers change.
          module V1_1
            # @returns [Boolean] whether `from` is required.
            def pagination_requires_from?
              true
            end

            # @returns [Symbol] the parameter name.
            def join_via_parameter
              :server_name
            end

            # Join this room, optionally explaining why.
            #
            # @parameter reason [String | nil] the reason for joining.
            def join_room_by_id(reason: nil, **payload)
              if reason
                payload[:reason] = reason
              end

              super(**payload)
            end

            # Leave this room, optionally explaining why.
            #
            # @parameter reason [String | nil] the reason for leaving.
            def leave_room(reason: nil, **payload)
              if reason
                payload[:reason] = reason
              end

              super(**payload)
            end
          end
        end
      end
    end
  end
end
