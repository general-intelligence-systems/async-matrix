# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/events"

# The field groups are shared between event types rather than inherited, because the specification
# does not relate the types which carry them: an image is not a kind of file, they simply describe
# an upload the same way.
describe Async::Matrix::Events::Captions do
  with "the formatting fields" do
    let(:content) {Async::Matrix::Events::TextMessage.new({format: "org.matrix.custom.html", formatted_body: "<b>hi</b>"})}

    it "reads the formatting fields" do
      expect(content.format).to be == "org.matrix.custom.html"
      expect(content.formatted_body).to be == "<b>hi</b>"
    end
  end

  with "an attachment" do
    let(:content) {Async::Matrix::Events::FileMessage.new({url: "mxc://localhost/1", info: {size: 12}})}

    it "reads how the upload is reached" do
      expect(content.url).to be == "mxc://localhost/1"
      expect(content.info).to be == {size: 12}
      expect(content.file).to be_nil
    end
  end

  with "a filename" do
    it "reads the original filename" do
      expect(Async::Matrix::Events::FileMessage.new({filename: "notes.txt"}).filename).to be == "notes.txt"
    end
  end
end
