# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/administrative_contact"

describe Async::Matrix::ClientServer::AdministrativeContact do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  let(:contact) {client.administrative_contact}

  # The user interactive authentication the homeserver asks for before it will touch the account. The rig accepts any password, so one round of it is enough.
  let(:auth) {{type: "m.login.password", identifier: {type: "m.id.user", user: self.user_id}, password: Async::Matrix::TEST_PASSWORD}}

  # Every one of these operations is in every version, so all of them are on the class rather than in layers.
  #
  # The rig has no identity server and no mail, which is the usual shape of a homeserver as far as these operations are concerned: half of them answer, and half refuse. A case for one which refuses asserts the refusal, since what it has to prove is that the request is the one the specification asked for and that it reached the homeserver.
  it "can getAccount3PIDs" do
    expect(contact.get_account_3pids).to be(:empty?)
  end

  it "can delete3pidFromAccount" do
    result = contact.delete_3pid_from_account("email", "nobody@example.com")

    expect(result.id_server_unbind_result).to be == "no-support"
    expect(result).not.to be(:unbound?)
  end

  it "can unbind3pidFromAccount" do
    expect(contact.unbind_3pid_from_account("email", "nobody@example.com").id_server_unbind_result).to be == "no-support"
  end

  # There is no validated session to quote, since nothing can validate one here.
  it "can add3PID" do
    error = nil

    begin
      contact.add_3pid("a-secret", "not-a-session", auth: auth)
    rescue Async::Matrix::RequestError => error
    end

    expect(error.errcode).to be == "M_THREEPID_AUTH_FAILED"
  end

  it "can post3PIDs" do
    error = nil

    begin
      contact.post_3pids({client_secret: "a-secret", id_server: "localhost", id_access_token: "not-a-token", sid: "not-a-session"})
    rescue Async::Matrix::RequestError => error
    end

    expect(error.errcode).to be == "M_THREEPID_AUTH_FAILED"
  end

  # Binding is the identity server's to do, and there is none, so the homeserver fails rather than refuses. The case asserts no more than that.
  it "can bind3PID" do
    expect do
      contact.bind_3pid("a-secret", "localhost", "not-a-token", "not-a-session")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The cases whose refusal the homeserver names differently from one version to the next:
  include Async::Matrix::Testing::Abstract::ClientServer::AdministrativeContact::CASES
end
