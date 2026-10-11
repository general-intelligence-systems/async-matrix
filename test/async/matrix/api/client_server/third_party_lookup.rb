# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/third_party_lookup"

describe Async::Matrix::ClientServer::ThirdPartyLookup do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operations are in every version, so the methods are on the class rather than in a layer.
  #
  # Bridging is an application service's to do, and the rig runs none, so the homeserver bridges to nothing: a lookup finds nobody rather than refusing, and a protocol it has never heard of is a refusal.
  it "can getProtocols" do
    protocols = client.third_party_lookup.get_protocols

    expect(protocols.names).to be_a(Array)
    expect(protocols).to be(:empty?)
  end

  it "can getProtocolMetadata" do
    error = nil

    begin
      client.third_party_lookup.get_protocol_metadata("irc")
    rescue Async::Matrix::RequestError => error
    end

    expect(error.status).to be == 404
  end

  it "can queryLocationByAlias" do
    expect(client.third_party_lookup.query_location_by_alias("#somewhere:localhost")).to be(:empty?)
  end

  it "can queryLocationByProtocol" do
    expect(client.third_party_lookup.query_location_by_protocol("irc", channel: "#somewhere")).to be(:empty?)
  end

  it "can queryUserByID" do
    expect(client.third_party_lookup.query_user_by_id(self.user_id)).to be(:empty?)
  end

  it "can queryUserByProtocol" do
    expect(client.third_party_lookup.query_user_by_protocol("irc", nick: "somebody")).to be(:empty?)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::ThirdPartyLookup::CASES
end
