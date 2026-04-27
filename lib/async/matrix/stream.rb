# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/http"
require "async/matrix"

module Async
  module Matrix
    class Stream < Async::HTTP::Protocol::HTTP2::Stream
    end
  end
end

test do
  it "inherits from Async::HTTP::Protocol::HTTP2::Stream" do
    Async::Matrix::Stream.ancestors.should.include Async::HTTP::Protocol::HTTP2::Stream
  end
end
