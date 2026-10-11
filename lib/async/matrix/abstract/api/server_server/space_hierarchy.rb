# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::SpaceHierarchy}.
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

          # v1.2 added spaces, and the rooms they hold.
          module V1_2
            # The rooms a space holds, as the server which has it reports them.
            #
            # One hop only: a server answers for the space it was asked about.
            #
            # @parameter room_id [String] the space to read.
            # @parameter suggested_only [Boolean | nil] whether to leave out the rooms which are not suggested.
            # @returns [Hierarchy] the space, and its children.
            def get_space_hierarchy(room_id, suggested_only: nil)
              path = "#{FEDERATION_V1}/hierarchy/#{::Protocol::URL::Encoding.escape(room_id)}"
              parameters = {suggested_only: suggested_only}.compact

              api::Hierarchy.get(@resource.with(path: path, parameters: parameters))
            end
          end

          # No changes in v1.1.
          module V1_1
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::Hierarchy}.
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

          # v1.2 answered with the space and its children.
          module V1_2
            # @returns [Hash] what the space itself is, as a stripped down room.
            def room
              self.value[:room] || {}
            end

            # @returns [String | nil] the space this hierarchy is of.
            def room_id
              self.room[:room_id]
            end

            # @returns [Array(Hash)] the rooms the space holds.
            def children
              self.value[:children] || []
            end

            # The children the asking server may not see, which it is told about rather than shown.
            #
            # @returns [Array(String)] the rooms it cannot read.
            def inaccessible_children
              self.value[:inaccessible_children] || []
            end

            # @returns [Array(String)] the IDs of the rooms the space holds.
            def child_ids
              self.children.map{|child| child[:room_id]}
            end

            # @returns [Boolean] whether the space holds nothing.
            def empty?
              self.children.empty?
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
