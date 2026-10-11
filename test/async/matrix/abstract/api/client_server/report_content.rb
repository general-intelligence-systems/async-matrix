# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the reports, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::ReportContent}.
          module ReportContent
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

            # v1.14 added reporting a user.
            module V1_14
              def self.included(base)
                base.it "can reportUser" do
                  expect(client.report_content.report_user(self.user_id, "a report from a test").value).to be == {}
                end
              end
            end

            # v1.13 renamed the report, and added reporting a room.
            module V1_13
              def self.included(base)
                base.let(:sent){room.send_message("m.room.message", {msgtype: "m.text", body: "something to report"})}

                base.it "can reportEvent" do
                  expect(client.report_content.report_event(room.id, sent.event_id, reason: "a report from a test", score: -100).value).to be == {}
                end

                base.it "can reportRoom" do
                  expect(client.report_content.report_room(room.id, reason: "a report from a test").value).to be == {}
                end

                # The method the report was reached by is still here, and says what became of it.
                base.it "says the report was renamed" do
                  error = nil

                  begin
                    client.report_content.report_content(room.id, sent.event_id)
                  rescue Async::Matrix::RemovedOperationError => error
                  end

                  expect(error.version).to be == "v1.13"
                  expect(error.replacement).to be == :report_event
                end
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
              # The operation this case exercises was renamed in v1.13, and so was the case.
              WITHDRAWN_IN = "v1.13"

              def self.included(base)
                base.let(:sent){room.send_message("m.room.message", {msgtype: "m.text", body: "something to report"})}

                base.it "can reportContent" do
                  expect(client.report_content.report_content(room.id, sent.event_id, reason: "a report from a test", score: -100).value).to be == {}
                end
              end
            end
            # The cases required at the version under test.
            #
            # A layer whose operations a later version renamed names that version, and is left out once the version under test has reached it: the cases follow the operations.
            CASES = Sus::Shared("report cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if ReportContent.const_defined?(name, false)
                  layer = ReportContent.const_get(name, false)

                  if layer.const_defined?(:WITHDRAWN_IN, false) and Async::Matrix::Versions.up_to(Async::Matrix::TEST_VERSION).include?(layer::WITHDRAWN_IN)
                    next
                  end

                  include layer
                end
              end
            end
          end
        end
      end
    end
  end
end
