# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/users"

describe Async::Matrix::ClientServer::Users do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer.
  #
  # A homeserver lists the users it chooses to, which for a user who shares no room with anybody is nobody: what the case proves is the search and what it answers with, not the homeserver's idea of who is public.
  it "can searchUserDirectory" do
    results = client.users.search_user_directory(self.username)

    expect(results.results).to be_a(Array)
    expect(results).to be(:empty?)
  end

  it "says whether the homeserver stopped short of every match" do
    expect(client.users.search_user_directory("someone", limit: 1).limited?).to be == false
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Users::CASES
end
