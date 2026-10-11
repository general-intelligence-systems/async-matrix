# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the push rules, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::PushRules}.
          module PushRules
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

            # v1.12 added reading the global scope on its own.
            module V1_12
              def self.included(base)
                base.it "can getPushRulesGlobal" do
                  global = client.pushrules.get_push_rules_global

                  expect(global.underride).not.to be(:empty?)
                  expect(global.content).to be_a(Array)
                end

                # The scope on its own is what the whole set carries under `global`.
                base.it "answers with what the whole set carries" do
                  expect(client.pushrules.get_push_rules_global.underride).to be == client.pushrules.get_push_rules.global[:underride]
                end
              end
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

            # No changes in v1.1.
            module V1_1
            end
            # The cases required at the version under test.
            CASES = Sus::Shared("push rule cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if PushRules.const_defined?(name, false)
                  include PushRules.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
