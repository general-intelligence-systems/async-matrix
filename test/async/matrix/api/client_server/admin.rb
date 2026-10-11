# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/admin"

describe Async::Matrix::ClientServer::Admin do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # Every version answers this one, so the method is on the class rather than in a layer.
  #
  # Synapse answers for the user asking without making them an administrator, which is what lets the case ask at all.
  it "can getWhoIs" do
    who = client.admin.get_who_is(self.user_id)

    expect(who.user_id).to be == self.user_id
    expect(who.devices).to be_a(Hash)
  end

  it "escapes the user in the path" do
    expect(Async::Matrix::ClientServer::Admin.path_for("@a user:localhost")).to be == "#{Async::Matrix::V3}/admin/whois/%40a%20user%3Alocalhost"
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Admin::CASES
end
