# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix"

describe Async::Matrix::Representation do
  it "wraps responses with the Matrix wrapper" do
    expect(subject::WRAPPER).to be_a(Async::Matrix::Wrapper::JSON)
  end
end
