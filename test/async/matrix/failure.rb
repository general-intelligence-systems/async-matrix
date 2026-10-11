# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/http/body/buffered"
require "protocol/http/response"

require "async/matrix/failure"

describe Async::Matrix::Failure do
  def response_for(body, status: 400)
    Protocol::HTTP::Response[status, {"content-type" => "application/json"}, body]
  end

  with ".for" do
    it "reads the error code and message" do
      failure = subject.for(response_for(["{\"errcode\":\"M_FORBIDDEN\",\"error\":\"Nope\"}"]))

      expect(failure.errcode).to be == "M_FORBIDDEN"
      expect(failure.message).to be == "Nope"
    end

    it "reads the rate limit delay" do
      failure = subject.for(response_for(["{\"errcode\":\"M_LIMIT_EXCEEDED\",\"retry_after_ms\":1500}"]))

      expect(failure.retry_after_ms).to be == 1500
    end

    it "leaves the response readable by the caller" do
      response = response_for(["{\"errcode\":\"M_FORBIDDEN\"}"])

      subject.for(response)

      expect(response.read).to be == "{\"errcode\":\"M_FORBIDDEN\"}"
    end

    it "can be read twice" do
      response = response_for(["{\"errcode\":\"M_FORBIDDEN\"}"])

      expect(subject.for(response).errcode).to be == "M_FORBIDDEN"
      expect(subject.for(response).errcode).to be == "M_FORBIDDEN"
    end

    it "reports nothing for a body which is not JSON" do
      expect(subject.for(response_for(["<html>502</html>"]))).to be_nil
    end

    it "leaves a body which is not JSON readable" do
      response = response_for(["<html>502</html>"])

      subject.for(response)

      expect(response.read).to be == "<html>502</html>"
    end

    it "reports nothing for a body which is not an object" do
      expect(subject.for(response_for(["[1,2,3]"]))).to be_nil
    end

    it "reports nothing when there is no body" do
      expect(subject.for(Protocol::HTTP::Response[204, {}, nil])).to be_nil
    end
  end

  with "#unknown_token?" do
    it "is an unknown token" do
      expect(subject.new({errcode: "M_UNKNOWN_TOKEN"})).to be(:unknown_token?)
    end

    it "is a missing token" do
      expect(subject.new({errcode: "M_MISSING_TOKEN"})).to be(:unknown_token?)
    end

    it "is not any other refusal" do
      expect(subject.new({errcode: "M_FORBIDDEN"})).not.to be(:unknown_token?)
    end
  end
end
