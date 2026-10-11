# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/version"

describe Async::Matrix do
  # The gem's own version, which is not a specification version.
  it "names its own version" do
    expect(Async::Matrix::VERSION).to be =~ /\A\d+\.\d+\.\d+\z/
  end
end
