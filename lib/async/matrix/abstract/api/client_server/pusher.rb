# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::Pusher}.
        module Pusher
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

          # v1.6 let a nil kind delete the pusher.
          module V1_6
            # Set a pusher, or take one away by giving its kind as nil.
            #
            # @parameter pushkey [String] the key the application gave for this device.
            # @parameter kind [String | nil] `http`, `email`, or nil to remove the pusher.
            # @parameter app_id [String] the application the key belongs to.
            # @parameter payload [Hash] the rest the specification allows, e.g. `data:`, `lang:`.
            # @returns [Representation] the empty response.
            def post_pusher(pushkey, kind, app_id, **payload)
              body = {pushkey: pushkey, kind: kind, app_id: app_id, **payload}

              api::Representation.post(@resource.with(path: "#{V3}/pushers/set"), body)
            end
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
