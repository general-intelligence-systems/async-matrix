# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/payload"

require "protocol/http/response"
require "protocol/http/body/buffered"

# Reads a payload the way the library does, since the method is private to whoever includes it.
class Reader
  include Async::Matrix::Payload

  def read(response)
    self.read_payload(response)
  end
end

describe Async::Matrix::Payload do
  let(:reader) {Reader.new}

  with "a JSON body" do
    let(:response) {Protocol::HTTP::Response[429, {}, ["{\"retry_after_ms\":1000}"]]}

    it "parses it" do
      expect(reader.read(response)).to be == {retry_after_ms: 1000}
    end

    it "leaves the body readable" do
      reader.read(response)

      expect(response.body.join).to be == "{\"retry_after_ms\":1000}"
    end
  end

  with "a body which is not JSON" do
    let(:response) {Protocol::HTTP::Response[502, {}, ["bad gateway"]]}

    it "reports nothing" do
      expect(reader.read(response)).to be_nil
    end

    # The body is replaced before it is parsed, so the caller still has it even when the parse fails.
    it "leaves the body readable" do
      reader.read(response)

      expect(response.body.join).to be == "bad gateway"
    end
  end

  with "no body" do
    let(:response) {Protocol::HTTP::Response[204, {}, nil]}

    it "reports nothing" do
      expect(reader.read(response)).to be_nil
    end
  end
end
