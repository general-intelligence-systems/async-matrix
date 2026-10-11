# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/http/body/buffered"
require "protocol/http/response"

require "async/rest/wrapper/json"

require "async/matrix/oauth/error"

describe Async::Matrix::OAuth::Error do
  it "is a request error, so a caller which handles one refusal handles both" do
    expect(subject.new(400, "invalid_grant")).to be_a(Async::Matrix::RequestError)
  end

  it "reports a rejected grant, which means the caller must authorize again" do
    expect(subject.new(400, "invalid_grant")).to be(:invalid_grant?)
  end

  it "does not report any other refusal as a rejected grant" do
    expect(subject.new(400, "invalid_request")).not.to be(:invalid_grant?)
  end
end

describe Async::Matrix::OAuth do
  with ".error_for" do
    # Read the way the wrappers read it: after the parser has been attached, so the body is a hash.
    def response_for(body, status: 400, parsed: true)
      ::Protocol::HTTP::Response[status, {"content-type" => "application/json"}, ::Protocol::HTTP::Body::Buffered.wrap(body)].tap do |response|
        if parsed
          response.body = ::Async::REST::Wrapper::JSON::Parser.new(response.body)
        end
      end
    end

    it "reads the code and description" do
      error, description = subject.error_for(response_for(["{\"error\":\"invalid_grant\",\"error_description\":\"Spent.\"}"]))

      expect(error).to be == "invalid_grant"
      expect(description).to be == "Spent."
    end

    # The server refused without saying why, which is still a refusal.
    it "reads a body with no code as an invalid request" do
      error, _ = subject.error_for(response_for(["{}"]))

      expect(error).to be == "invalid_request"
    end

    it "reads a body which is not an object as an invalid request" do
      error, description = subject.error_for(response_for(["<html>502</html>"], parsed: false))

      expect(error).to be == "invalid_request"
      expect(description).to be(:include?, "502")
    end
  end
end
