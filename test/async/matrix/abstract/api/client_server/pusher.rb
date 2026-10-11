# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the pusher operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::Pusher}.
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

            # v1.6 let kind be nil, which deletes the pusher.
            module V1_6
              def self.included(base)
                base.it "can delete a pusher by giving its kind as nil" do
                  client.pusher.post_pusher(pushkey, "http", "com.example.app",
                    app_display_name: "An Application",
                    device_display_name: "A Device",
                    lang: "en",
                    data: {url: "https://example.com/_matrix/push/v1/notify"},
                  )

                  client.pusher.post_pusher(pushkey, nil, "com.example.app")

                  expect(client.pusher.get_pushers.pushkeys).not.to be(:include?, pushkey)
                end
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

            # The cases required at the version under test.
            CASES = Sus::Shared("pusher cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Pusher.const_defined?(name, false)
                  include Pusher.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
