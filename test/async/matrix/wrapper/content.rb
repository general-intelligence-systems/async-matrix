# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/wrapper/content"

require "protocol/http/request"

describe Async::Matrix::Wrapper::Content do
  let(:wrapper) {subject.new}

  let(:request) {::Protocol::HTTP::Request["GET", "/"]}

  # A download sends nothing, and a body built from nothing is not a body.
  it "sends no body where there is nothing to send" do
    wrapper.prepare_request(request, nil)

    expect(request.body).to be_nil
  end

  it "sends the bytes it is given, as they are" do
    wrapper.prepare_request(request, "the bytes")

    expect(request.body.join).to be == "the bytes"
  end

  # The type belongs to the caller, which sets it on the resource: a wrapper which set one would send two.
  it "leaves the content type to the caller" do
    wrapper.prepare_request(request, "the bytes")

    expect(request.headers["content-type"]).to be_nil
  end
end

describe Async::Matrix::Wrapper::Upload do
  let(:wrapper) {subject.new}

  let(:request) {::Protocol::HTTP::Request["POST", "/"]}

  # An upload is bytes going up and a document coming back.
  it "sends the bytes it is given, as they are" do
    wrapper.prepare_request(request, "the bytes")

    expect(request.body.join).to be == "the bytes"
  end

  it "asks for a document back" do
    wrapper.prepare_request(request, "the bytes")

    expect(request.headers["accept"]).to be(:include?, "application/json")
  end

  it "leaves the content type to the caller" do
    wrapper.prepare_request(request, "the bytes")

    expect(request.headers["content-type"]).to be_nil
  end

  # The bytes are not a document, so they are not encoded as one.
  it "does not encode the bytes as JSON" do
    wrapper.prepare_request(request, "\xFF\xD8\xFF".b)

    expect(request.body.join).to be == "\xFF\xD8\xFF".b
  end
end
