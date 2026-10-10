# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

# The version layers for `sync.rb`. Each module mirrors the class of the same name, and holds only
# what a given specification version changed: the unversioned implementation stays in the class.
#
# Every version is declared, highest first, even when it changed nothing, so that a missing module
# is a mistake rather than a deliberate no-op. The schemas beside this file say what each version
# requires, and `sync.rb-<version>.deltas.yaml` says what it changed.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::Sync}.
        module Sync
          # No changes in v1.19.
          module V1_19
          end

          # No changes in v1.18.
          module V1_18
          end

          # No changes in v1.17.
          module V1_17
          end

          # v1.16 added the `use_state_after` request parameter, and the `state_after` response field
          # which replaces `state` when it is used.
          module V1_16
            module ClassMethods
              # @parameter use_state_after [Boolean] request `state_after` instead of `state`.
              def start(resource, use_state_after: false, **options)
                options[:use_state_after] = true if use_state_after

                super(resource, **options)
              end
            end

            # @parameter room_id [String] the room to look up.
            # @returns [Array(Hash) | nil] the state after the timeline, if it was requested.
            def state_after(room_id)
              self.joined.dig(room_id.to_sym, :state_after, :events)
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

          # v1.4 added per-thread notification counts.
          module V1_4
            # @parameter room_id [String] the room to look up.
            # @returns [Hash | nil] the unread counts per thread, keyed by root event ID.
            def unread_thread_notifications(room_id)
              self.joined.dig(room_id.to_sym, :unread_thread_notifications)
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
        end
      end
    end
  end
end
