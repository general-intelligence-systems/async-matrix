# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/middleware/repeatable"

describe Async::Matrix::Middleware::Repeatable do
  let(:repeatable) do
    Object.new.tap do |object|
      object.singleton_class.include(subject)
      object.singleton_class.send(:public, :repeatable?, :rewind)
    end
  end

  with "#repeatable?" do
    it "is repeatable with no body" do
      expect(repeatable.repeatable?(Protocol::HTTP::Request["GET", "/"])).to be == true
    end

    it "is repeatable with a body which can be replayed" do
      body = Protocol::HTTP::Body::Buffered.new(["payload"])

      expect(repeatable.repeatable?(Protocol::HTTP::Request["POST", "/", nil, body])).to be == true
    end
  end

  with "#rewind" do
    it "winds a body which has been read back" do
      body = Protocol::HTTP::Body::Buffered.new(["payload"])
      request = Protocol::HTTP::Request["POST", "/", nil, body]

      body.join
      repeatable.rewind(request)

      expect(body.join).to be == "payload"
    end

    it "does nothing when there is no body" do
      expect(repeatable.rewind(Protocol::HTTP::Request["GET", "/"])).to be_nil
    end
  end
end
