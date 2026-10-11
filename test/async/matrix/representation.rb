# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix"

describe Async::Matrix::Representation do
  it "wraps responses with the Matrix wrapper" do
    expect(subject::WRAPPER).to be_a(Async::Matrix::Wrapper)
  end
end
