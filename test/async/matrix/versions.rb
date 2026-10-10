# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix"

describe Async::Matrix::Versions do
  with ".normalize" do
    it "accepts a version with or without the prefix" do
      expect(subject.normalize("v1.19")).to be == "v1.19"
      expect(subject.normalize("1.19")).to be == "v1.19"
    end

    it "rejects an unknown version" do
      expect do
        subject.normalize("v2.0")
      end.to raise_exception(Async::Matrix::UnsupportedVersionError)
    end
  end

  with ".layer_name" do
    it "maps a version onto a constant name" do
      expect(subject.layer_name("v1.19")).to be == :V1_19
      expect(subject.layer_name("v1.1")).to be == :V1_1
    end
  end

  with ".up_to" do
    it "lists the versions up to and including the given one" do
      expect(subject.up_to("v1.3")).to be == ["v1.1", "v1.2", "v1.3"]
    end
  end

  with ".layers_for" do
    it "lists the layers in ascending order" do
      expect(subject.layers_for("v1.3")).to be == [:V1_1, :V1_2, :V1_3]
    end
  end

  with ".classes" do
    # A class opts in by including Async::Matrix::Versioned, so there is no registry to keep in
    # step with the classes themselves.
    it "discovers the classes which include Versioned" do
      classes = subject.classes(Async::Matrix::ClientServer)

      expect(classes[:Client]).to be_equal(Async::Matrix::ClientServer::Client)
      expect(classes[:Room]).to be_equal(Async::Matrix::ClientServer::Room)
      expect(classes[:Sync]).to be_equal(Async::Matrix::ClientServer::Sync)
    end

    it "does not include classes which are not versioned" do
      expect(subject.classes(Async::Matrix::ClientServer).keys).not.to be(:include?, :Representation)
      expect(subject.classes(Async::Matrix::ClientServer).keys).not.to be(:include?, :RequestError)
    end
  end

  with ".[]" do
    it "builds one class per versioned class" do
      api = subject["v1.19"]

      expect(api::SPEC_VERSION).to be == "v1.19"

      subject.classes(Async::Matrix::ClientServer).each_key do |name|
        expect(api.const_get(name)).to be < Async::Matrix::ClientServer.const_get(name)
      end
    end

    it "shares the classes which are not versioned" do
      expect(subject["v1.19"]::Representation).to be_equal(Async::Matrix::Representation)
    end

    it "caches what it builds" do
      expect(subject["v1.19"]).to be_equal(subject["v1.19"])
    end
  end
end

describe Async::Matrix::ClientServer::Client do
  with ".[]" do
    it "returns the client for a version" do
      expect(subject["v1.19"]).to be_equal(Async::Matrix::Versions["v1.19"]::Client)
      expect(subject["v1.19"].version).to be == "v1.19"
    end

    it "derives from the unversioned client" do
      expect(subject["v1.1"]).to be < subject
      expect(subject["v1.19"]).to be < subject
    end

    it "is a distinct class per version" do
      expect(subject["v1.1"]).not.to be_equal(subject["v1.19"])
    end

    it "has a readable name" do
      expect(subject["v1.19"].to_s).to be == "Async::Matrix::ClientServer::Client[\"v1.19\"]"
    end

    it "rejects an unknown version" do
      expect do
        subject["v0.9"]
      end.to raise_exception(Async::Matrix::UnsupportedVersionError)
    end
  end

  with "#api" do
    # `Async::Matrix::VERSION` is the gem's version, and an unversioned class resolves its api to
    # its own namespace, so this must not report the gem version by accident.
    it "reports no version when the class is not versioned" do
      expect(subject.version).to be_nil
      expect(subject.api).to be_equal(Async::Matrix::ClientServer)
    end

    it "resolves peers at its own version" do
      client = subject["v1.15"]

      expect(client.api::Room).to be_equal(Async::Matrix::Versions["v1.15"]::Room)
      expect(client.api::Sync).to be_equal(Async::Matrix::Versions["v1.15"]::Sync)
    end

    it "resolves peers to the unversioned classes when it is not versioned" do
      expect(subject.api::Room).to be_equal(Async::Matrix::ClientServer::Room)
    end
  end
end

describe Async::Matrix::Abstract do
  with "version layers" do
    # Abstract::Sync::V1_16 adds `state_after`.
    it "applies a layer only from the version which introduced it" do
      expect(Async::Matrix::ClientServer::Client["v1.15"].api::Sync.instance_methods).not.to be(:include?, :state_after)
      expect(Async::Matrix::ClientServer::Client["v1.16"].api::Sync.instance_methods).to be(:include?, :state_after)
      expect(Async::Matrix::ClientServer::Client["v1.19"].api::Sync.instance_methods).to be(:include?, :state_after)
    end

    it "applies class method layers by extending rather than including" do
      start = Async::Matrix::ClientServer::Client["v1.16"].api::Sync.method(:start)

      expect(start.owner).to be_equal(Async::Matrix::Abstract::ClientServer::Sync::V1_16::ClassMethods)
      expect(start.parameters.map(&:last)).to be(:include?, :use_state_after)
    end

    it "leaves the unversioned class alone" do
      expect(Async::Matrix::ClientServer::Sync.instance_methods).not.to be(:include?, :state_after)
      expect(Async::Matrix::ClientServer::Sync.method(:start).owner).to be_equal(Async::Matrix::ClientServer::Sync.singleton_class)
    end

    # Abstract::Room::V1_1 names the servers to join through `server_name`, and
    # Abstract::Room::V1_12 renames it to `via`, so both layers define the same method.
    it "stacks layers so that the newest wins" do
      room = Async::Matrix::ClientServer::Client["v1.19"].api::Room

      expect(room.instance_method(:join_via_parameter).owner).to be_equal(Async::Matrix::Abstract::ClientServer::Room::V1_12)

      ancestors = room.ancestors

      expect(ancestors.index(Async::Matrix::Abstract::ClientServer::Room::V1_12)).to be < ancestors.index(Async::Matrix::Abstract::ClientServer::Room::V1_1)
      expect(ancestors.index(Async::Matrix::Abstract::ClientServer::Room::V1_1)).to be < ancestors.index(Async::Matrix::ClientServer::Room)
    end

    it "reaches the earlier implementation through super" do
      room = Async::Matrix::ClientServer::Client["v1.11"].api::Room

      # v1.12 is not applied, so the parameter name comes from the v1.1 layer:
      expect(room.instance_method(:join_via_parameter).owner).to be_equal(Async::Matrix::Abstract::ClientServer::Room::V1_1)

      # ...and `join`, which v1.1 overrides to carry `reason`, reaches the unversioned class
      # through super:
      expect(room.instance_method(:join).owner).to be_equal(Async::Matrix::Abstract::ClientServer::Room::V1_1)
      expect(room.instance_method(:join).super_method.owner).to be_equal(Async::Matrix::ClientServer::Room)
    end
  end
end
