# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/pushrules"

describe Async::Matrix::ClientServer::PushRules do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  let(:rules) {client.pushrules}

  # A rule of this test's own, since the homeserver's own rules are not ours to move.
  let(:rule_id) {"com.example.async_matrix.#{SecureRandom.hex(6)}"}

  # The rule exists once it has been set, which every case but the first needs.
  let(:rule) {rules.set_push_rule("global", "sender", rule_id, ["notify"])}

  # Eight of the nine operations are in every version, so their methods are on the class rather than in a layer.
  it "can getPushRules" do
    expect(rules.get_push_rules.global).to be(:include?, :underride)
  end

  it "can setPushRule" do
    expect(rules.set_push_rule("global", "sender", rule_id, ["notify"]).value).to be == {}
  end

  it "can getPushRule" do
    rule

    read = rules.get_push_rule("global", "sender", rule_id)

    expect(read.rule_id).to be == rule_id
    expect(read.actions).to be == ["notify"]
    expect(read).not.to be(:default?)
    expect(read).to be(:enabled?)
  end

  it "can deletePushRule" do
    rule

    expect(rules.delete_push_rule("global", "sender", rule_id).value).to be == {}

    expect do
      rules.get_push_rule("global", "sender", rule_id)
    end.to raise_exception(Async::Matrix::RequestError)
  end

  it "can getPushRuleActions" do
    rule

    expect(rules.get_push_rule_actions("global", "sender", rule_id).actions).to be == ["notify"]
  end

  it "can setPushRuleActions" do
    rule

    expect(rules.set_push_rule_actions("global", "sender", rule_id, ["dont_notify"]).value).to be == {}
    expect(rules.get_push_rule_actions("global", "sender", rule_id).actions).to be == ["dont_notify"]
  end

  it "can isPushRuleEnabled" do
    rule

    expect(rules.is_push_rule_enabled("global", "sender", rule_id)).to be(:enabled?)
  end

  it "can setPushRuleEnabled" do
    rule

    expect(rules.set_push_rule_enabled("global", "sender", rule_id, false).value).to be == {}
    expect(rules.is_push_rule_enabled("global", "sender", rule_id)).not.to be(:enabled?)
  end

  # The rules the homeserver makes are marked as its own, and carry what they match on.
  it "reads the rules the homeserver made" do
    read = rules.get_push_rule("global", "underride", ".m.rule.message")

    expect(read).to be(:default?)
    expect(read.conditions).not.to be(:empty?)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::PushRules::CASES
end
