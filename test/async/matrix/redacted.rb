# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/redacted"
require "async/matrix/representation"

describe Async::Matrix::Redacted do
  with ".redact" do
    it "replaces the value of a secret" do
      expect(subject.redact({access_token: "secret"})).to be == {access_token: "[redacted]"}
    end

    it "leaves everything else alone" do
      expect(subject.redact({user_id: "@alice:localhost"})).to be == {user_id: "@alice:localhost"}
    end

    it "replaces a secret nested in a hash" do
      expect(subject.redact({session: {refresh_token: "secret"}})).to be == {session: {refresh_token: "[redacted]"}}
    end

    it "replaces a secret nested in an array" do
      expect(subject.redact([{password: "secret"}])).to be == [{password: "[redacted]"}]
    end

    it "leaves a value which is not a collection alone" do
      expect(subject.redact("plain")).to be == "plain"
    end
  end

  with "#inspect" do
    let(:resource) {Async::REST::Resource.new(nil)}
    let(:representation) {Async::Matrix::Representation.new(resource, value: {access_token: "secret", refresh_token: "secret", user_id: "@alice:localhost"})}

    it "does not print a secret" do
      expect(representation.inspect).not.to be(:include?, "secret")
    end

    it "prints everything else" do
      expect(representation.inspect).to be(:include?, "@alice:localhost")
    end
  end
end
