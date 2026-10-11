# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::PublicRooms}.
        module PublicRooms
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

          # v1.1 read the rooms a server publishes.
          module V1_1
            # The rooms a server publishes, as a page.
            #
            # @parameter limit [Integer | nil] the most rooms wanted.
            # @parameter since [String | nil] the token a previous page ended at.
            # @parameter include_all_networks [Boolean | nil] whether to include the bridged networks.
            # @parameter third_party_instance_id [String | nil] one bridged network to read instead.
            # @returns [PublishedRooms] the page of rooms.
            def get_public_rooms(limit: nil, since: nil, include_all_networks: nil, third_party_instance_id: nil)
              parameters = {limit: limit, since: since, include_all_networks: include_all_networks, third_party_instance_id: third_party_instance_id}.compact

              api::PublishedRooms.get(@resource.with(path: "#{FEDERATION_V1}/publicRooms", parameters: parameters))
            end

            # The rooms a server publishes, narrowed by a filter.
            #
            # The filter is why this is a POST: it does not fit in a query string.
            #
            # @parameter filter [Hash | nil] what to search for, e.g. `generic_search_term`.
            # @parameter limit [Integer | nil] the most rooms wanted.
            # @parameter since [String | nil] the token a previous page ended at.
            # @parameter options [Hash] whatever else the version takes.
            # @returns [PublishedRooms] the page of rooms.
            def query_public_rooms(filter: nil, limit: nil, since: nil, **options)
              payload = {filter: filter, limit: limit, since: since}.compact.merge(options)

              api::PublishedRooms.post(@resource.with(path: "#{FEDERATION_V1}/publicRooms"), payload)
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::PublishedRooms}.
        module PublishedRooms
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

          # v1.1 answered with a page of rooms.
          module V1_1
            # @returns [Array(Hash)] the rooms in this page.
            def chunk
              self.value[:chunk] || []
            end

            # @returns [String | nil] the token to ask for the following page from.
            def next_batch
              self.value[:next_batch]
            end

            # @returns [String | nil] the token to ask for the preceding page from.
            def prev_batch
              self.value[:prev_batch]
            end

            # An estimate, because a server counts the rooms it will show rather than all of them.
            #
            # @returns [Integer | nil] roughly how many rooms there are.
            def total_room_count_estimate
              self.value[:total_room_count_estimate]
            end

            # @returns [Array(String)] the IDs of the rooms in this page.
            def room_ids
              self.chunk.map{|entry| entry[:room_id]}
            end

            # @returns [Boolean] whether this page is empty.
            def empty?
              self.chunk.empty?
            end
          end
        end
      end
    end
  end
end
