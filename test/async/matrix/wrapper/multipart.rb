# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/http/body/buffered"
require "protocol/http/request"
require "protocol/http/response"

require "async/matrix/wrapper/multipart"

describe Async::Matrix::Wrapper::Multipart do
  let(:boundary) {"c20053a69a2f456b8f394607b74c3b33"}

  let(:wrapper) {subject.new}

  # The answer Synapse sends: a JSON part which describes the file, and then the file.
  def multipart(described: "{}", headers: ["Content-Type: text/plain", "Content-Disposition: inline; filename=hello.txt"], content: "hello federation")
    [
      "",
      "--#{boundary}",
      "Content-Type: application/json",
      "",
      described,
      "--#{boundary}",
      *headers,
      "",
      content,
      "--#{boundary}--",
      "",
    ].join("\r\n")
  end

  def response_for(bytes, content_type: "multipart/mixed; boundary=#{boundary}", status: 200)
    Protocol::HTTP::Response[status, {"content-type" => content_type}, [bytes]]
  end

  with ".boundary_for" do
    it "reads the boundary the response declares" do
      expect(subject.boundary_for(response_for(""))).to be == boundary
    end

    it "reads a boundary which was quoted" do
      expect(subject.boundary_for(response_for("", content_type: "multipart/mixed; boundary=\"#{boundary}\""))).to be == boundary
    end

    it "reads no boundary from a response which is not multipart" do
      expect(subject.boundary_for(response_for("", content_type: "application/json"))).to be_nil
    end

    it "reads no boundary from a response which declares no type" do
      expect(subject.boundary_for(Protocol::HTTP::Response[200, {}, []])).to be_nil
    end
  end

  with ".parse" do
    it "reads what the first part says about the file" do
      parsed = subject.parse(multipart(described: "{\"org.matrix.msc4034.unstable\":true}"), boundary)

      expect(parsed[:metadata]).to be == {"org.matrix.msc4034.unstable": true}
    end

    it "reads the file from the second part" do
      parsed = subject.parse(multipart, boundary)

      expect(parsed[:bytes]).to be == "hello federation"
      expect(parsed[:content_type]).to be == "text/plain"
      expect(parsed[:content_disposition]).to be == "inline; filename=hello.txt"
    end

    # The second part may say where the file is rather than carry it.
    it "reads where the file is, where the part redirects" do
      parsed = subject.parse(multipart(headers: ["Location: https://elsewhere.test/file"], content: ""), boundary)

      expect(parsed[:location]).to be == "https://elsewhere.test/file"
      expect(parsed[:bytes]).to be == ""
    end

    # The boundary is chosen so as not to appear within a part, so a newline in the file is just a newline.
    it "reads a file which has newlines in it" do
      parsed = subject.parse(multipart(content: "one\r\ntwo\r\nthree"), boundary)

      expect(parsed[:bytes]).to be == "one\r\ntwo\r\nthree"
    end

    it "reads an empty document where the first part says nothing" do
      parsed = subject.parse(multipart(described: ""), boundary)

      expect(parsed[:metadata]).to be == {}
    end
  end

  with "#wrap_response" do
    it "reads the parts rather than the bytes" do
      response = wrapper.wrap_response(response_for(multipart))

      expect(response.read[:bytes]).to be == "hello federation"
    end

    it "leaves a response which is not multipart alone" do
      response = wrapper.wrap_response(response_for("nope", content_type: "text/plain"))

      expect(response.read).to be == "nope"
    end
  end

  with "#process_response" do
    it "raises the refusal a server answered with" do
      response = response_for("{\"errcode\":\"M_NOT_FOUND\",\"error\":\"Not found\"}", content_type: "application/json", status: 404)

      expect do
        wrapper.process_response(Protocol::HTTP::Request["GET", "/"], response)
      end.to raise_exception(Async::Matrix::RequestError, message: be =~ /Not found/)
    end

    it "parses a response the server answered with" do
      response = wrapper.process_response(Protocol::HTTP::Request["GET", "/"], response_for(multipart))

      expect(response.read[:content_type]).to be == "text/plain"
    end
  end

  with "#prepare_request" do
    it "asks for the two part answer" do
      request = Protocol::HTTP::Request["GET", "/"]

      wrapper.prepare_request(request, nil)

      expect(request.headers["accept"]).to be(:include?, "multipart/mixed")
    end
  end
end
