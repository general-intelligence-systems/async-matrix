# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/application_service_context"
require "async/matrix/operations_context"

describe Async::Matrix::ApplicationService::Protocols do
  include Async::Matrix::ApplicationServiceContext
  include Async::Matrix::OperationsContext

  let(:protocol) {Async::Matrix::APPLICATION_SERVICE_PROTOCOL}

  it "can getProtocolMetadata" do
    described = service.protocols.get_protocol_metadata(protocol)

    expect(described.user_fields).to be(:include?, "nick")
    expect(described.location_fields).to be(:include?, "channel")
    expect(described.instances).not.to be(:empty?)
  end

  it "can queryUserByProtocol" do
    found = service.protocols.query_user_by_protocol(protocol, nick: "stub")

    expect(found.entries.first[:userid]).to be == Async::Matrix::APPLICATION_SERVICE_USER
  end

  it "can queryUserByID" do
    found = service.protocols.query_user_by_id(Async::Matrix::APPLICATION_SERVICE_USER)

    expect(found.entries.first[:protocol]).to be == protocol
  end

  it "can queryLocationByProtocol" do
    found = service.protocols.query_location_by_protocol(protocol, channel: "#stub")

    expect(found.entries.first[:alias]).to be == Async::Matrix::APPLICATION_SERVICE_ALIAS
  end

  it "can queryLocationByAlias" do
    found = service.protocols.query_location_by_alias(Async::Matrix::APPLICATION_SERVICE_ALIAS)

    expect(found.entries.first[:alias]).to be == Async::Matrix::APPLICATION_SERVICE_ALIAS
  end

  # A protocol the service does not bridge to is one it has nothing to say about.
  it "describes no protocol it does not bridge" do
    expect do
      service.protocols.get_protocol_metadata("nowhere")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  it "finds nobody for an address it does not know" do
    expect(service.protocols.query_user_by_id("@nobody:localhost")).to be(:empty?)
  end
end
