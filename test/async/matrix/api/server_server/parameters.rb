# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/api/server_server/parameters"

describe Async::Matrix::ServerServer::Parameters do
  with ".repeated" do
    # `Protocol::URL::Reference` would write `v[]=`, which a server does not read.
    it "gives the parameter once per value" do
      expect(subject.repeated("v", ["one", "two"])).to be == "v=one&v=two"
    end

    it "escapes each value" do
      expect(subject.repeated("v", ["$one"])).to be == "v=%24one"
    end

    it "takes a single value as one" do
      expect(subject.repeated("ver", "11")).to be == "ver=11"
    end

    it "says nothing where there are no values" do
      expect(subject.repeated("v", [])).to be == ""
    end
  end

  with ".query" do
    it "writes the repeated parameters and then the single ones" do
      expect(subject.query(repeated: {v: ["a", "b"]}, single: {limit: 10})).to be == "v=a&v=b&limit=10"
    end

    it "leaves out a single parameter which was not given" do
      expect(subject.query(repeated: {v: ["a"]}, single: {limit: nil})).to be == "v=a"
    end

    it "writes nothing where nothing was given" do
      expect(subject.query).to be == ""
    end

    it "leaves out a repeated parameter with no values" do
      expect(subject.query(repeated: {v: []}, single: {limit: 1})).to be == "limit=1"
    end
  end

  with ".path" do
    it "appends the query to the path" do
      expect(subject.path("/a", "v=1")).to be == "/a?v=1"
    end

    it "leaves the path alone where there is no query" do
      expect(subject.path("/a", "")).to be == "/a"
    end
  end
end
