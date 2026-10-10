# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

# The version layers for `rooms.rb`. Each module mirrors the class of the same name, and holds only
# what a given specification version changed: the unversioned implementation stays in the class.
#
# Every version is declared, highest first, even when it changed nothing - so that a missing module
# is a mistake rather than a deliberate no-op. The order is for readers: {ruby Async::Matrix::Versions}
# applies layers in ascending order whatever order they appear in here.

module Async
  module Matrix
    module Abstract
      # Layers for {ruby Async::Matrix::Room}.
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

        # v1.12 added the `via` parameter, which names servers to attempt the join through.
        module V1_12
          # Join this room, optionally by way of the given servers.
          #
          # @parameter via [Array(String) | nil] the servers to attempt the join through.
          def join(via: nil, **options)
            @resource = @resource.with(parameters: {via: via}) if via

            super(**options)
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

        # No changes in v1.3.
        module V1_3
        end

        # No changes in v1.2.
        module V1_2
        end

        # v1.1 added `reason` to the membership endpoints.
        module V1_1
          # Join this room, optionally explaining why.
          #
          # @parameter reason [String | nil] the reason for joining.
          def join(reason: nil, **payload)
            payload[:reason] = reason if reason

            super(**payload)
          end

          # Leave this room, optionally explaining why.
          #
          # @parameter reason [String | nil] the reason for leaving.
          def leave(reason: nil, **payload)
            payload[:reason] = reason if reason

            super(**payload)
          end
        end
      end
    end
  end
end
