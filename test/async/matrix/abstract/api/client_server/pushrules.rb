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

            # v1.12 hardcoded `global` and dropped `scope` from the other seven.
            module V1_12
              def self.included(base)
                base.let(:rule_id){"com.example.async_matrix.#{SecureRandom.hex(6)}"}

                base.it "can getPushRulesGlobal" do
                  global = client.pushrules.get_push_rules_global

                  expect(global.underride).not.to be(:empty?)
                  expect(global.content).to be_a(Array)
                end

                # The scope on its own is what the whole set carries under `global`.
                base.it "answers with what the whole set carries" do
                  expect(client.pushrules.get_push_rules_global.underride).to be == client.pushrules.get_push_rules.global[:underride]
                end

                base.it "can setPushRule" do
                  expect(client.pushrules.set_push_rule("sender", rule_id, ["notify"]).value).to be == {}
                end

                base.it "can getPushRule" do
                  client.pushrules.set_push_rule("sender", rule_id, ["notify"])

                  read = client.pushrules.get_push_rule("sender", rule_id)

                  expect(read.rule_id).to be == rule_id
                  expect(read.actions).to be == ["notify"]
                end

                base.it "can deletePushRule" do
                  client.pushrules.set_push_rule("sender", rule_id, ["notify"])

                  expect(client.pushrules.delete_push_rule("sender", rule_id).value).to be == {}

                  expect do
                    client.pushrules.get_push_rule("sender", rule_id)
                  end.to raise_exception(Async::Matrix::RequestError)
                end

                base.it "can getPushRuleActions" do
                  client.pushrules.set_push_rule("sender", rule_id, ["notify"])

                  expect(client.pushrules.get_push_rule_actions("sender", rule_id).actions).to be == ["notify"]
                end

                base.it "can setPushRuleActions" do
                  client.pushrules.set_push_rule("sender", rule_id, ["notify"])

                  expect(client.pushrules.set_push_rule_actions("sender", rule_id, ["dont_notify"]).value).to be == {}
                  expect(client.pushrules.get_push_rule_actions("sender", rule_id).actions).to be == ["dont_notify"]
                end

                base.it "can isPushRuleEnabled" do
                  client.pushrules.set_push_rule("sender", rule_id, ["notify"])

                  expect(client.pushrules.is_push_rule_enabled("sender", rule_id)).to be(:enabled?)
                end

                base.it "can setPushRuleEnabled" do
                  client.pushrules.set_push_rule("sender", rule_id, ["notify"])

                  expect(client.pushrules.set_push_rule_enabled("sender", rule_id, false).value).to be == {}
                  expect(client.pushrules.is_push_rule_enabled("sender", rule_id)).not.to be(:enabled?)
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

            # v1.1 took `scope` positionally, which v1.12 hardcoded and dropped.
            module V1_1
              # The operations these cases exercise dropped `scope` in v1.12, and so did the cases.
              WITHDRAWN_IN = "v1.12"

              def self.included(base)
                base.let(:rule_id){"com.example.async_matrix.#{SecureRandom.hex(6)}"}

                base.it "can setPushRule" do
                  expect(client.pushrules.set_push_rule("global", "sender", rule_id, ["notify"]).value).to be == {}
                end

                base.it "can getPushRule" do
                  client.pushrules.set_push_rule("global", "sender", rule_id, ["notify"])

                  read = client.pushrules.get_push_rule("global", "sender", rule_id)

                  expect(read.rule_id).to be == rule_id
                  expect(read.actions).to be == ["notify"]
                  expect(read).not.to be(:default?)
                  expect(read).to be(:enabled?)
                end

                base.it "can deletePushRule" do
                  client.pushrules.set_push_rule("global", "sender", rule_id, ["notify"])

                  expect(client.pushrules.delete_push_rule("global", "sender", rule_id).value).to be == {}

                  expect do
                    client.pushrules.get_push_rule("global", "sender", rule_id)
                  end.to raise_exception(Async::Matrix::RequestError)
                end

                base.it "can getPushRuleActions" do
                  client.pushrules.set_push_rule("global", "sender", rule_id, ["notify"])

                  expect(client.pushrules.get_push_rule_actions("global", "sender", rule_id).actions).to be == ["notify"]
                end

                base.it "can setPushRuleActions" do
                  client.pushrules.set_push_rule("global", "sender", rule_id, ["notify"])

                  expect(client.pushrules.set_push_rule_actions("global", "sender", rule_id, ["dont_notify"]).value).to be == {}
                  expect(client.pushrules.get_push_rule_actions("global", "sender", rule_id).actions).to be == ["dont_notify"]
                end

                base.it "can isPushRuleEnabled" do
                  client.pushrules.set_push_rule("global", "sender", rule_id, ["notify"])

                  expect(client.pushrules.is_push_rule_enabled("global", "sender", rule_id)).to be(:enabled?)
                end

                base.it "can setPushRuleEnabled" do
                  client.pushrules.set_push_rule("global", "sender", rule_id, ["notify"])

                  expect(client.pushrules.set_push_rule_enabled("global", "sender", rule_id, false).value).to be == {}
                  expect(client.pushrules.is_push_rule_enabled("global", "sender", rule_id)).not.to be(:enabled?)
                end

                # The rules the homeserver makes are marked as its own, and carry what they match on.
                base.it "reads the rules the homeserver made" do
                  read = client.pushrules.get_push_rule("global", "underride", ".m.rule.message")

                  expect(read).to be(:default?)
                  expect(read.conditions).not.to be(:empty?)
                end
              end
            end
            # The cases required at the version under test.
            #
            # A layer whose operations a later version withdrew names that version, and is left out once the version under test has reached it: the cases go the way the operations did.
            CASES = Sus::Shared("push rule cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if PushRules.const_defined?(name, false)
                  layer = PushRules.const_get(name, false)

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
