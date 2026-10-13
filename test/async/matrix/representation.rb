# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix"

require "async/matrix/client_context"

describe Async::Matrix::Representation do
  it "wraps responses with the Matrix wrapper" do
    expect(subject::WRAPPER).to be_a(Async::Matrix::Wrapper::JSON)
  end

  # What the specification asks of a document is asked of the document itself, so anybody holding one may ask.
  with "#validate" do
    include Async::Matrix::ClientContext

    # The login response, which is the clearest thing the specification requires fields of.
    let(:session) {self.account(self.username)}

    it "finds nothing wrong with what the homeserver answered" do
      expect(session.get_token_owner.errors).to be(:empty?)
      expect(session.get_token_owner).to be(:valid?)
    end

    it "answers itself, so that it can be used where it is read" do
      whoami = session.get_token_owner

      expect(whoami.validate).to be_equal(whoami)
      expect(whoami.validate.user_id).to be == self.user_id
    end

    # The path is what says which operation answered, so nothing has to be told.
    it "finds the operation from the path it was fetched by" do
      expect(session.get_capabilities).to be(:valid?)
    end

    # A document which came from no version's class cannot say what describes it, and nothing is asked of it.
    it "asks nothing of a document which names no version" do
      expect(subject.new(session.get_token_owner.resource, value: {}).errors).to be(:empty?)
    end

    it "takes the operation it is named, wherever that operation's schema lives" do
      expect(session.get_token_owner.errors(operation: "getTokenOwner")).to be(:empty?)
    end

    # A document is checked against the version it was built for, and nothing is asked of a version which describes neither.
    it "asks nothing where the version describes no such operation" do
      expect(session.get_token_owner.errors(operation: "nothingOfTheKind")).to be(:empty?)
    end

    it "raises where the document is not what the operation describes" do
      whoami = session.get_token_owner
      error = nil

      begin
        whoami.class.new(whoami.resource, value: {device_id: "DEVICE"}).validate
      rescue Async::Matrix::InvalidDocumentError => error
      end

      expect(error.errors.first).to be(:include?, "user_id")
      expect(error.version).to be == Async::Matrix::TEST_VERSION
    end
  end
end
