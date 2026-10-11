# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/content"

describe Async::Matrix::Content do
  # The representation is built from a response, so the case builds one the same way.
  let(:content) do
    subject.new(nil, value: "the bytes", metadata: {"content-type" => "text/plain", "content-disposition" => "inline; filename=\"a.txt\""})
  end

  it "answers with the bytes" do
    expect(content.bytes).to be == "the bytes"
  end

  it "says what the bytes are" do
    expect(content.content_type).to be == "text/plain"
  end

  it "says what the homeserver suggests the file is called" do
    expect(content.content_disposition).to be =~ /a\.txt/
  end

  it "counts the bytes rather than the characters" do
    expect(subject.new(nil, value: "\xC3\xA9".b).size).to be == 2
  end
end

describe Async::Matrix::Uploaded do
  it "reads its answer as a document" do
    expect(subject::WRAPPER).to be_a(Async::Matrix::Wrapper::Upload)
  end
end
