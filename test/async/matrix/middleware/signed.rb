# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "json"

require "protocol/http/body/buffered"
require "protocol/http/middleware"
require "protocol/http/request"
require "protocol/http/response"

require "async/matrix/middleware/signed"
require "async/matrix/server_key"

describe Async::Matrix::Middleware::Signed do
  # Records what it was asked to send, and answers without a homeserver.
  class Recorder < Protocol::HTTP::Middleware
    def initialize
      super(nil)

      @requests = []
    end

    attr :requests

    def call(request)
      @requests << request

      Protocol::HTTP::Response[200, {}, []]
    end
  end

  let(:key) {Async::Matrix::ServerKey.parse("ed25519 a_pxTp SnDmunk28k36o2ibXNWobfWLBguwZDy3xFsNprjwl+c")}

  let(:recorder) {Recorder.new}

  let(:signed) {subject.new(recorder, "origin.test", key, "destination.test")}

  # The parameters of the authorization header, by name.
  def authorization_of(request)
    header = request.headers["authorization"]

    expect(header).to be(:start_with?, "X-Matrix ")

    header.delete_prefix("X-Matrix ").split(",").to_h do |parameter|
      name, value = parameter.split("=", 2)

      [name, value.delete_prefix("\"").delete_suffix("\"")]
    end
  end

  def get(path)
    signed.call(Protocol::HTTP::Request["GET", path])

    recorder.requests.last
  end

  def put(path, payload)
    body = Protocol::HTTP::Body::Buffered.new([JSON.generate(payload)])

    signed.call(Protocol::HTTP::Request["PUT", path, {}, body])

    recorder.requests.last
  end

  with "#call" do
    it "signs a request which carries no body" do
      parameters = authorization_of(get("/_matrix/federation/v1/version"))

      expect(parameters["origin"]).to be == "origin.test"
      expect(parameters["destination"]).to be == "destination.test"
      expect(parameters["key"]).to be == "ed25519:a_pxTp"
    end

    # The signature is over the request, so the other side can rebuild the object and check it.
    it "signs the method, the path, the origin and the destination" do
      request = get("/_matrix/federation/v1/version")
      parameters = authorization_of(request)

      expected = {
        method: "GET",
        uri: "/_matrix/federation/v1/version",
        origin: "origin.test",
        destination: "destination.test",
      }

      expect(key.verify(expected, parameters["sig"])).to be == true
    end

    # The parameters are part of the path, and part of what was signed.
    it "signs the parameters along with the path" do
      request = get("/_matrix/federation/v1/state/!a:b?event_id=$c")

      expected = {
        method: "GET",
        uri: "/_matrix/federation/v1/state/!a:b?event_id=$c",
        origin: "origin.test",
        destination: "destination.test",
      }

      expect(key.verify(expected, authorization_of(request)["sig"])).to be == true
    end

    # Signing the bytes would make the signature depend on how the sender wrote them, so it is over the document.
    it "signs the body as a document" do
      request = put("/_matrix/federation/v1/send/txn", {b: 2, a: 1})

      expected = {
        method: "PUT",
        uri: "/_matrix/federation/v1/send/txn",
        origin: "origin.test",
        destination: "destination.test",
        content: {a: 1, b: 2},
      }

      expect(key.verify(expected, authorization_of(request)["sig"])).to be == true
    end

    # Reading the body to sign it would otherwise leave nothing to send.
    it "leaves the body readable by the delegate" do
      request = put("/_matrix/federation/v1/send/txn", {a: 1})

      expect(request.body.join).to be == JSON.generate({a: 1})
    end

    it "replaces an authorization header the resource supplied" do
      request = Protocol::HTTP::Request["GET", "/_matrix/federation/v1/version", {"authorization" => "Bearer nope"}]

      signed.call(request)

      expect(recorder.requests.last.headers["authorization"]).to be(:start_with?, "X-Matrix ")
    end

    it "answers the delegate's response" do
      expect(signed.call(Protocol::HTTP::Request["GET", "/_matrix/federation/v1/version"]).status).to be == 200
    end
  end

  with "#inspect" do
    it "says which server it signs as" do
      expect(signed.inspect).to be(:include?, "origin.test")
      expect(signed.inspect).to be(:include?, "ed25519:a_pxTp")
    end
  end
end
