# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix"

describe Async::Matrix::Versioned do
  with "an unversioned class" do
    it "resolves its api to the namespace it lives in" do
      expect(Async::Matrix::ClientServer::Client.api).to be_equal(Async::Matrix::ClientServer)
    end

    # `Async::Matrix::VERSION` is the gem's version, so this must not report it by accident.
    it "reports no version" do
      expect(Async::Matrix::ClientServer::Client.version).to be_nil
    end

    it "resolves its peers to the unversioned classes" do
      expect(Async::Matrix::ClientServer::Client.api::Room).to be_equal(Async::Matrix::ClientServer::Room)
    end
  end

  with "a versioned class" do
    let(:client) {Async::Matrix::ClientServer::Client["v1.15"]}

    it "reports the version it was built for" do
      expect(client.version).to be == "v1.15"
    end

    it "resolves its peers at its own version" do
      expect(client.api::Room).to be_equal(Async::Matrix::Versions["v1.15"]::Room)
      expect(client.api::Sync).to be_equal(Async::Matrix::Versions["v1.15"]::Sync)
    end

    it "answers for an instance as well as a class" do
      instance = client.new(nil)

      expect(instance.version).to be == "v1.15"
      expect(instance.api).to be_equal(client.api)
    end
  end
end
