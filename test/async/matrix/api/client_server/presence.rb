# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/presence"

describe Async::Matrix::ClientServer::Presence do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operations are in every version, so the methods are on the class rather than in a layer.
  it "can setPresence" do
    expect(client.presence.set_presence(self.user_id, "online", status_msg: "testing").value).to be == {}
  end

  it "can getPresence" do
    client.presence.set_presence(self.user_id, "online", status_msg: "testing")

    status = client.presence.get_presence(self.user_id)

    expect(status.presence).to be == "online"
    expect(status.status_msg).to be == "testing"
    expect(status).to be(:currently_active?)
  end

  it "reports how long ago the user was active" do
    client.presence.set_presence(self.user_id, "online")

    expect(client.presence.get_presence(self.user_id).last_active_ago).to be_a(Integer)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Presence::CASES
end
