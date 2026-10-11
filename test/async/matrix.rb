# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix"

# The entry point requires everything the library offers, so loading it is a test in its own right:
# a require which is missing or out of order fails here rather than in whichever suite happens to load first.
describe Async::Matrix do
  it "has a version" do
    expect(Async::Matrix::VERSION).to be =~ /\A\d+\.\d+\.\d+\z/
  end

  it "knows which specification versions it supports" do
    expect(Async::Matrix::VERSIONS).not.to be(:empty?)
    expect(Async::Matrix::LATEST).to be == Async::Matrix::VERSIONS.last
  end

  it "exposes the client-server API" do
    expect(Async::Matrix::ClientServer::Client).to be_a(Class)
  end

  it "builds every supported version" do
    Async::Matrix::VERSIONS.each do |version|
      expect(Async::Matrix::ClientServer::Client[version].version).to be == version
    end
  end
end
