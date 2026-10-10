# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

# The version layers for `rooms.rb`. Each module mirrors the class of the same name, and holds only
# what a given specification version changed: the unversioned implementation stays in the class.
#
# Every version is declared, highest first, even when it changed nothing, so that a missing module
# is a mistake rather than a deliberate no-op. The schemas beside this file say what each version
# requires, and `rooms.rb-<version>.deltas.yaml` says what it changed.

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

          # v1.12 renamed the servers to attempt a join through from `server_name` to `via`. Both
          # are accepted until v1.14, which removes `server_name`, so there is nothing further to
          # do at that version.
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

          # v1.3 made the `from` token optional when paging the timeline, so that a client can page
          # from either end of the history rather than having to hold a token first.
          module V1_3
            # @returns [Boolean] whether `from` is required.
            def pagination_requires_from?
              false
            end
          end

          # No changes in v1.2.
          module V1_2
          end

          # v1.1 is the oldest version this library supports. It carries the behaviour the later
          # layers change: `reason` on the membership endpoints, a required `from` when paging, and
          # `server_name` for the servers to attempt a join through.
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
            def join(reason: nil, **payload)
              if reason
                payload[:reason] = reason
              end

              super(**payload)
            end

            # Leave this room, optionally explaining why.
            #
            # @parameter reason [String | nil] the reason for leaving.
            def leave(reason: nil, **payload)
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
