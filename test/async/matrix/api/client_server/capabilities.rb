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
