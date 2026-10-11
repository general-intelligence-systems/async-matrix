# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

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

          # v1.16 added `format`, choosing content alone or the whole event.
          module V1_16
            # @parameter type [String] the event type, e.g. `m.room.name`.
            # @parameter state_key [String] the state key, which is usually empty.
            # @parameter format [String | nil] `content` for the content alone, `event` for the event.
            # @returns [StateEvent] the state event.
            def get_room_state_with_key(type, state_key = "", format: nil)
              parameters = {format: format}.compact

              api::StateEvent.get(@resource.with(path: self.state_path(type, state_key), parameters: parameters))
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
