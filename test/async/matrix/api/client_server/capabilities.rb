# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/capabilities"

describe Async::Matrix::ClientServer::Capabilities do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The cases for the operation itself, layered by the version which introduced each capability:
  include Async::Matrix::Testing::Abstract::ClientServer::Capabilities::CASES

  with "the version it was built for" do
    def readers(version)
      Async::Matrix::ClientServer::Client[version].api::Capabilities.instance_methods
    end

    # The schemas say which version describes which capability, so a client built for an older one has no reader for one that version never named.
    it "gains the account readers at v1.12" do
      expect(readers("v1.11")).not.to be(:include?, :set_displayname?)
      expect(readers("v1.11")).not.to be(:include?, :third_party_identifier_changes?)
      expect(readers("v1.12")).to be(:include?, :set_displayname?)
      expect(readers("v1.12")).to be(:include?, :third_party_identifier_changes?)
    end

    it "gains the profile field readers at v1.16" do
      expect(readers("v1.15")).not.to be(:include?, :profile_fields?)
      expect(readers("v1.16")).to be(:include?, :profile_fields?)
    end

    it "gains the moderation readers at v1.18" do
      expect(readers("v1.17")).not.to be(:include?, :suspend_accounts?)
      expect(readers("v1.18")).to be(:include?, :suspend_accounts?)
      expect(readers("v1.18")).to be(:include?, :forget_forced_upon_leave?)
    end

    # The capabilities have been an open map since v1.1, so reading one by name needs no version.
    it "reads a capability by name at every version" do
      expect(readers("v1.1")).to be(:include?, :enabled?)
      expect(readers("v1.1")).to be(:include?, :change_password?)
    end
  end

  with "#[]" do
    it "answers what the homeserver said about a capability" do
      expect(client.get_capabilities["m.change_password"]).to be == {enabled: true}
    end

    it "answers nothing for a capability which was not advertised" do
      expect(client.get_capabilities["com.example.nonsense"]).to be_nil
    end

    it "takes the name as a string or a symbol" do
      capabilities = client.get_capabilities

      expect(capabilities[:"m.change_password"]).to be == capabilities["m.change_password"]
    end
  end

  with "#enabled?" do
    # Absent and disabled are different answers, and a caller which cannot tell them apart will get one of them wrong.
    it "answers nothing for a capability which was not advertised" do
      expect(client.get_capabilities.enabled?("com.example.nonsense")).to be_nil
    end

    # A capability which carries no `enabled` field, such as the room versions, says nothing about being enabled.
    it "answers nothing for a capability which does not say" do
      expect(client.get_capabilities.enabled?("m.room_versions")).to be_nil
    end
  end
end
