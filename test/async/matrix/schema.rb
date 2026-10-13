# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/schema"

describe Async::Matrix::Schema do
  # The login response is the clearest case the specification offers: v1.4 made three of its fields required, and v1.3 required none of them.
  let(:session) {subject.for("client_server", "session", "v1.4")}

  let(:earlier) {subject.for("client_server", "session", "v1.3")}

  let(:complete) {{user_id: "@alice:localhost", access_token: "a-token", device_id: "DEVICE"}}

  with ".for" do
    it "reads the schema for the version it was asked for" do
      expect(session.version).to be == "v1.4"
      expect(session.operations).to be(:key?, "login")
    end

    it "answers nothing for a concept the version does not describe" do
      expect(subject.for("client_server", "nothing_of_the_kind", "v1.19")).to be_nil
    end

    # The schema keeps the specification's own name, which may be hyphenated where a Ruby file cannot be.
    it "reads a concept whose schema is named with hyphens" do
      expect(subject.for("client_server", "content_repo", "v1.19")).not.to be_nil
    end

    it "reads the same schema once, however often it is asked for" do
      expect(subject.for("client_server", "session", "v1.4")).to be_equal(session)
    end

    it "reads the events the event schemas describe" do
      expect(subject.for("events", "m.room.message", "v1.19").events).to be(:key?, "m.room.message")
    end
  end

  with ".concepts" do
    it "names every concept an API describes at a version" do
      expect(subject.concepts("push_gateway", "v1.19")).to be == ["push_notifier"]
      expect(subject.concepts("client_server", "v1.19")).to be(:include?, "session")
    end

    # A deltas file sits beside each schema and describes it rather than being one.
    it "names no deltas file" do
      expect(subject.concepts("client_server", "v1.19").grep(/deltas/)).to be(:empty?)
    end
  end

  with "#required_in_response" do
    # This is what the version changed, and what nothing in the library read until there was something to read it.
    it "names the fields the version requires" do
      expect(session.required_in_response("login")).to be == [:user_id, :access_token, :device_id]
    end

    it "names none where the version required none" do
      expect(earlier.required_in_response("login")).to be(:empty?)
    end

    it "names none for a response the version does not describe" do
      expect(session.required_in_response("login", status: 418)).to be(:empty?)
    end
  end

  with "#errors_in_response" do
    it "finds nothing wrong with a document which answers the version" do
      expect(session.errors_in_response("login", complete)).to be(:empty?)
    end

    it "says which required fields a document is missing" do
      errors = session.errors_in_response("login", {user_id: "@alice:localhost"})

      expect(errors.size).to be == 1
      expect(errors.first).to be(:include?, "access_token")
      expect(errors.first).to be(:include?, "device_id")
    end

    # The same document was acceptable before the version which required them.
    it "finds nothing wrong with the same document at the version before" do
      expect(earlier.errors_in_response("login", {user_id: "@alice:localhost"})).to be(:empty?)
    end

    it "says where a field is not the type the schema gives it" do
      expect(session.errors_in_response("login", complete.merge(access_token: 7)).first).to be(:include?, "not string")
    end

    # A server may send fields a version does not describe, and a client which refused them would break on the next version rather than on a fault.
    it "allows a field the version does not describe" do
      expect(session.errors_in_response("login", complete.merge(invented_by_the_server: true))).to be(:empty?)
    end

    # A nested object is checked as the object it is: `well_known` is optional, but what it holds is not.
    it "checks what a nested object requires, where there is one" do
      expect(session.errors_in_response("login", complete.merge(well_known: {}))).not.to be(:empty?)
      expect(session.errors_in_response("login", complete.merge(well_known: {"m.homeserver": {base_url: "https://localhost"}}))).to be(:empty?)
    end

    # The documents this library reads are keyed by symbol, because a Matrix document is read by pattern matching.
    it "reads a document keyed by string as readily as one keyed by symbol" do
      expect(session.errors_in_response("login", complete.transform_keys(&:to_s))).to be(:empty?)
    end

    it "finds nothing wrong where the version describes no such response" do
      expect(session.errors_in_response("login", {}, status: 418)).to be(:empty?)
    end
  end

  with "#validate_response" do
    it "answers the document where it is acceptable" do
      expect(session.validate_response("login", complete)).to be == complete
    end

    it "raises where it is not, saying which operation and version refused it" do
      error = nil

      begin
        session.validate_response("login", {})
      rescue Async::Matrix::InvalidDocumentError => error
      end

      expect(error.operation).to be == "login"
      expect(error.version).to be == "v1.4"
      expect(error.errors.first).to be(:include?, "access_token")
      expect(error.message).to be(:include?, "v1.4")
    end
  end

  with "#request" do
    # A request is checked the same way, which is what a client owes rather than what it is owed.
    it "builds a schema from what the operation sends" do
      expect(session.request("login")).to be(:key?, "properties")
      expect(session.required_in_request("login")).to be(:include?, :type)
    end

    it "says where a request is missing what it must carry" do
      expect(session.errors_in_request("login", {}).first).to be(:include?, "type")
    end

    it "finds nothing wrong with a request which carries it" do
      expect(session.errors_in_request("login", {type: "m.login.password", password: "hunter2"})).to be(:empty?)
    end
  end

  with "#response" do
    # An array's members are described by a map in a list of one, which becomes the schema for a member.
    it "builds a schema for the members of an array" do
      flows = subject.for("client_server", "session", "v1.19").response("getLoginFlows")

      expect(flows.dig("properties", "flows", "type")).to be == "array"
      expect(flows.dig("properties", "flows", "items", "required")).to be == ["type"]
    end

    it "answers nothing where the version describes no such response" do
      expect(session.response("login", status: 418)).to be_nil
    end
  end
end
