# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::SpaceHierarchy}.
        module SpaceHierarchy
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

          # v1.2 added the hierarchy of a space.
          module V1_2
            # The rooms a space holds, and the spaces they hold in turn.
            #
            # @parameter room_id [String] the space to walk.
            # @parameter suggested_only [Boolean | nil] whether to take only the rooms the space suggests.
            # @parameter limit [Integer | nil] the most rooms wanted.
            # @parameter max_depth [Integer | nil] how far down to walk.
            # @parameter from [String | nil] the token a previous page ended at.
            # @returns [Hierarchy] the page of rooms.
            def get_space_hierarchy(room_id, suggested_only: nil, limit: nil, max_depth: nil, from: nil)
              parameters = {suggested_only: suggested_only, limit: limit, max_depth: max_depth, from: from}.compact
              path = "#{V1}/rooms/#{::Protocol::URL::Encoding.escape(room_id)}/hierarchy"

              api::Hierarchy.get(@resource.with(path: path, parameters: parameters))
            end
          end

          # No changes in v1.1.
          module V1_1
          end
        end

        # Layers for {ruby Async::Matrix::ClientServer::Hierarchy}.
        module Hierarchy
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

          # v1.2 added the hierarchy, which pages through the rooms.
          module V1_2
            # @returns [Array(Hash)] the rooms in this page, each summarised.
            def rooms
              self.value[:rooms] || []
            end

            # @returns [String | nil] the token to ask for the following page from.
            def next_batch
              self.value[:next_batch]
            end

            # @returns [Boolean] whether this page is empty.
            def empty?
              self.rooms.empty?
            end
          end

          # No changes in v1.1.
          module V1_1
          end
        end
      end
    end
  end
end
