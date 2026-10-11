# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/search"

describe Async::Matrix::ClientServer::Search do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  let(:needle) {"needle-#{SecureRandom.hex(6)}"}

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can search" do
    room.send_message("m.room.message", {msgtype: "m.text", body: needle})

    results = client.search.search({room_events: {search_term: needle}})

    expect(results.count).to be == 1
    expect(results.results.first[:result][:content][:body]).to be == needle
  end

  it "finds nothing for a term nobody sent" do
    expect(client.search.search({room_events: {search_term: needle}})).to be(:empty?)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Search::CASES
end
