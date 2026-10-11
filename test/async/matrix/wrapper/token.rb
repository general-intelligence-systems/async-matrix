# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/http/request"
require "protocol/http/response"

require "sus/fixtures/async/reactor_context"

require "async/matrix/wrapper/token"

describe Async::Matrix::Wrapper::Token do
  include Sus::Fixtures::Async::ReactorContext

  let(:wrapper) {subject.new}

  with "#parser_for" do
    # The authorization server need not say what an empty body is, and a response with no content type is left alone rather than raising.
    it "leaves a response with no content type alone" do
      response = ::Protocol::HTTP::Response[200, {}, []]

      expect(wrapper.parser_for(response)).to be_nil
    end

    it "parses a response which says it is JSON" do
      response = ::Protocol::HTTP::Response[200, {"content-type" => "application/json"}, ["{}"]]

      expect(wrapper.parser_for(response)).to be == Async::REST::Wrapper::JSON::Parser
    end
  end

  with "#process_response" do
    let(:request) {::Protocol::HTTP::Request["POST", "/oauth2/token"]}

    it "returns a response the server accepted" do
      response = ::Protocol::HTTP::Response[200, {"content-type" => "application/json"}, ["{}"]]

      expect(wrapper.process_response(request, response)).to be_equal(response)
    end

    it "raises what the server refused" do
      response = ::Protocol::HTTP::Response[400, {"content-type" => "application/json"}, ["{\"error\":\"invalid_grant\",\"error_description\":\"Spent.\"}"]]

      error = nil

      begin
        wrapper.process_response(request, response)
      rescue Async::Matrix::OAuth::Error => raised
        error = raised
      end

      expect(error).not.to be_nil
      expect(error).to be(:invalid_grant?)
      expect(error.status).to be == 400
      expect(error.message).to be(:include?, "Spent.")
    end

    # A caller which already handles a refusal from the homeserver handles this one too.
    it "raises a request error" do
      response = ::Protocol::HTTP::Response[400, {"content-type" => "application/json"}, ["{\"error\":\"invalid_request\"}"]]

      expect do
        wrapper.process_response(request, response)
      end.to raise_exception(Async::Matrix::RequestError)
    end
  end
end
