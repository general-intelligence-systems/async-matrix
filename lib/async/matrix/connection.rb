# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/http"

module Async
  module Matrix
    module Connection
      include Async::HTTP::Protocol::HTTP2::Connection
    end
  end
end

__END__
  it "includes Async::HTTP::Protocol::HTTP2::Connection" do
    Async::Matrix::Connection.ancestors.should.include Async::HTTP::Protocol::HTTP2::Connection
  end
