# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identifier/opaque"

describe Async::Matrix::Identifier::Opaque do
  with ".valid?" do
    # The unreserved set of RFC 3986, which is what survives being put in a URL untouched.
    it "accepts the characters the grammar allows" do
      ["AAAAAAAAAAAA", "a-b.c_d~e", "0", "a" * 255].each do |string|
        expect(subject.valid?(string)).to be == true
      end
    end

    it "refuses anything else, and anything too long" do
      ["has spaces", "a/b", "a:b", "", "a" * 256].each do |string|
        expect(subject.valid?(string)).to be == false
      end
    end
  end
end
