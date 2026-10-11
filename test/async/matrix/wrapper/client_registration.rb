# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/http/request"
require "protocol/http/response"

require "sus/fixtures/async/reactor_context"

require "async/matrix/wrapper/client_registration"

describe Async::Matrix::Wrapper::ClientRegistration do
  include Sus::Fixtures::Async::ReactorContext

  let(:wrapper) {subject.new}

  let(:request) {::Protocol::HTTP::Request["POST", "/oauth2/registration"]}

  # Registering a client is the one request sent as JSON, so it has its own refusal path.
  it "sends the client metadata as JSON" do
    wrapper.prepare_request(request, {client_name: "async-matrix"})

    expect(request.headers["content-type"]).to be == "application/json"
    expect(request.body.join).to be == "{\"client_name\":\"async-matrix\"}"
  end

  it "returns a response the server accepted" do
    response = ::Protocol::HTTP::Response[201, {"content-type" => "application/json"}, ["{\"client_id\":\"a-client\"}"]]

    expect(wrapper.process_response(request, response)).to be_equal(response)
  end

  it "raises what the server refused" do
    response = ::Protocol::HTTP::Response[400, {"content-type" => "application/json"}, ["{\"error\":\"invalid_client_metadata\"}"]]

    error = nil

    begin
      wrapper.process_response(request, response)
    rescue Async::Matrix::OAuth::Error => raised
      error = raised
    end

    expect(error).not.to be_nil
    expect(error.errcode).to be == "invalid_client_metadata"
    expect(error.status).to be == 400
  end
end
