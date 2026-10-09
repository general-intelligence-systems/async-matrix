# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/http"

module Async
  module Matrix
  end
end

# The message FORMAT layer: events, content, schemas, encrypted messages. It
# does no IO, so it lives beside the other protocol-* libraries rather than
# under the gem that opens sockets. Required FIRST, because the aliases below
# and the client both depend on it.
require "protocol/matrix"

module Async
  module Matrix
    # Where these constants used to live. Kept as aliases so code written
    # against 3.0 keeps working; new code should name Protocol::Matrix directly.
    Event = ::Protocol::Matrix::Event
    Content = ::Protocol::Matrix::Content
    Schema = ::Protocol::Matrix::Schema
  end
end

Dir.glob("#{__dir__}/matrix/**/*.rb").sort.each do |path|
  require path
end
