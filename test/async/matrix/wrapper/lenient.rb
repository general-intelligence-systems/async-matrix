# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/wrapper/lenient"

require "protocol/http/response"

describe Async::Matrix::Wrapper::Lenient do
  let(:wrapper) {subject.new}

  def response_for(content_type)
    if content_type
      headers = {"content-type" => content_type}
    else
      headers = {}
    end

    ::Protocol::HTTP::Response[200, headers, []]
  end

  it "reads a body which says it is a document" do
    expect(wrapper.parser_for(response_for("application/json"))).to be_equal(subject::Parser)
  end

  # Which is the whole point: a push gateway sends a document and says it is a page.
  it "reads a body which says it is something else" do
    expect(wrapper.parser_for(response_for("text/html"))).to be_equal(subject::Parser)
  end

  it "reads a body which says nothing at all" do
    expect(wrapper.parser_for(response_for(nil))).to be_equal(subject::Parser)
  end
end
