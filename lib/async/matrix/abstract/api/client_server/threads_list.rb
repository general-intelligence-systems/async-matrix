# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::ThreadsList}.
        module ThreadsList
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

          # v1.4 added the list of threads.
          module V1_4
            # The events which start the threads of a room.
            #
            # @parameter room_id [String] the room to read.
            # @parameter include [String | nil] `all` for every thread, or `participated` for this user's.
            # @parameter limit [Integer | nil] the most threads wanted.
            # @parameter from [String | nil] the token a previous page ended at.
            # @returns [ThreadRoots] the page of threads.
            def get_thread_roots(room_id, include: nil, limit: nil, from: nil)
              parameters = {include: include, limit: limit, from: from}.compact
              path = "#{V1}/rooms/#{::Protocol::URL::Encoding.escape(room_id)}/threads"

              api::ThreadRoots.get(@resource.with(path: path, parameters: parameters))
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

        # Layers for {ruby Async::Matrix::ClientServer::ThreadRoots}.
        module ThreadRoots
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

          # v1.4 added the list, which pages through the threads.
          module V1_4
            # @returns [Array(Hash)] the events which start the threads in this page.
            def chunk
              self.value[:chunk] || []
            end

            # @returns [String | nil] the token to ask for the following page from.
            def next_batch
              self.value[:next_batch]
            end

            # @returns [Boolean] whether this page is empty.
            def empty?
              self.chunk.empty?
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
