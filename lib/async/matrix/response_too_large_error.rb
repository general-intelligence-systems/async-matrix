# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Async::Matrix::Error is this class's superclass, so it has to exist before
# this file finishes loading — the glob in async/matrix.rb sorts
# alphabetically and would otherwise get here first.
require_relative "error"

module Async
  module Matrix
    class ResponseTooLargeError < Error; end
  end
end

__END__
  it "ResponseTooLargeError inherits from Error" do
    Async::Matrix::ResponseTooLargeError.new("M_TOO_LARGE", "too big").should.be.kind_of Async::Matrix::Error
  end
