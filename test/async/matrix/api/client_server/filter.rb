# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/filter"

describe Async::Matrix::ClientServer::Filter do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operations are in every version, so the methods are on the class rather than in a layer.
  it "can defineFilter" do
    expect(client.filter.define_filter(self.user_id, {room: {timeline: {limit: 1}}}).filter_id).to be_a(String)
  end

  it "can getFilter" do
    defined = client.filter.define_filter(self.user_id, {room: {timeline: {limit: 3}}})

    expect(client.filter.get_filter(self.user_id, defined.filter_id).room).to be == {timeline: {limit: 3}}
  end

  # A filter the homeserver never stored is not a filter it will answer for.
  it "fails for a filter which was never defined" do
    expect do
      client.filter.get_filter(self.user_id, "not-a-filter")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Filter::CASES
end
