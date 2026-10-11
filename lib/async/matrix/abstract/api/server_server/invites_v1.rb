# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::InvitesV1}.
        module InvitesV1
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

          # v1.1 invited a user, without the room version.
          module V1_1
            # Ask another server to tell one of its users they are invited.
            #
            # Only room versions 1 and 2 read it: it carries no room version.
            #
            # @parameter room_id [String] the room the invite is to.
            # @parameter event_id [String] the ID of the signed invite event.
            # @parameter event [Hash] the signed invite event.
            # @returns [InvitedEventV1] the event, wrapped in a status.
            def send_invite_v1(room_id, event_id, event)
              path = "#{FEDERATION_V1}/invite/#{::Protocol::URL::Encoding.escape(room_id)}/#{::Protocol::URL::Encoding.escape(event_id)}"

              api::InvitedEventV1.put(@resource.with(path: path), event)
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::InvitedEventV1}.
        module InvitedEventV1
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

          # v1.1 answered with a status beside the body.
          module V1_1
            # The first version answered `[200, {...}]`, which v2 replaced with the body alone.
            #
            # @returns [Hash] the body, whichever way it was wrapped.
            def body
              if self.value.is_a?(Array)
                self.value.last
              else
                self.value
              end
            end

            # @returns [Hash] the event, as both servers have it.
            def event
              self.body[:event] || {}
            end
          end
        end
      end
    end
  end
end
