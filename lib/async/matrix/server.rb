# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/http"

module Async
  module Matrix
    class Server < Async::HTTP::Protocol::HTTP2::Server
    end
  end
end

test do
  it "inherits from Async::HTTP::Protocol::HTTP2::Server" do
    Async::Matrix::Server.ancestors.should.include Async::HTTP::Protocol::HTTP2::Server
  end
end
