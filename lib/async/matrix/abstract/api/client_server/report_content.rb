# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::ReportContent}.
        module ReportContent
          # No changes in v1.19.
          module V1_19
          end

          # v1.18 dropped the score, leaving only the reason.
          module V1_18
            # Report an event to the administrators of this homeserver.
            #
            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event to report.
            # @parameter reason [String | nil] why it is being reported.
            # @returns [Representation] the empty response.
            def report_event(room_id, event_id, reason: nil)
              payload = {reason: reason}.compact

              api::Representation.post(@resource.with(path: self.report_path_for(room_id, event_id)), payload)
            end
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

          # v1.14 added user reports, and required the room report's reason.
          module V1_14
            # Report a user to the administrators of this homeserver.
            #
            # @parameter user_id [String] the user to report.
            # @parameter reason [String] why they are being reported.
            # @returns [Representation] the empty response.
            def report_user(user_id, reason)
              path = "#{V3}/users/#{::Protocol::URL::Encoding.escape(user_id)}/report"

              api::Representation.post(@resource.with(path: path), {reason: reason})
            end

            # Report a room to the administrators of this homeserver.
            #
            # @parameter room_id [String] the room to report.
            # @parameter reason [String] why it is being reported.
            # @returns [Representation] the empty response.
            def report_room(room_id, reason:)
              api::Representation.post(@resource.with(path: self.report_path_for(room_id)), {reason: reason})
            end
          end

          # v1.13 renamed the report, and added reporting a room.
          module V1_13
            extend Removals

            removed :report_content, use: :report_event

            # Report an event to the administrators of this homeserver.
            #
            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event to report.
            # @parameter reason [String | nil] why it is being reported.
            # @parameter score [Integer | nil] how bad it is, from -100 to 0.
            # @returns [Representation] the empty response.
            def report_event(room_id, event_id, reason: nil, score: nil)
              payload = {reason: reason, score: score}.compact

              api::Representation.post(@resource.with(path: self.report_path_for(room_id, event_id)), payload)
            end

            # Report a room to the administrators of this homeserver.
            #
            # @parameter room_id [String] the room to report.
            # @parameter reason [String | nil] why it is being reported.
            # @returns [Representation] the empty response.
            def report_room(room_id, reason: nil)
              payload = {reason: reason}.compact

              api::Representation.post(@resource.with(path: self.report_path_for(room_id)), payload)
            end
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

          # v1.1 named the report after the content it was about.
          module V1_1
            # Report an event to the administrators of this homeserver.
            #
            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event to report.
            # @parameter reason [String | nil] why it is being reported.
            # @parameter score [Integer | nil] how bad it is, from -100 to 0.
            # @returns [Representation] the empty response.
            def report_content(room_id, event_id, reason: nil, score: nil)
              payload = {reason: reason, score: score}.compact

              api::Representation.post(@resource.with(path: self.report_path_for(room_id, event_id)), payload)
            end

            # @parameter room_id [String] the room reported, or the room the event is in.
            # @parameter event_id [String | nil] the event reported, where it is an event.
            # @returns [String] the path to report to.
            def report_path_for(room_id, event_id = nil)
              path = "#{V3}/rooms/#{::Protocol::URL::Encoding.escape(room_id)}/report"

              if event_id
                path = "#{path}/#{::Protocol::URL::Encoding.escape(event_id)}"
              end

              path
            end
          end
        end
      end
    end
  end
end
