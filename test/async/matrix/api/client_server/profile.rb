# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/profile"

describe Async::Matrix::ClientServer::Profile do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # Every version answers for the whole profile, so the method is on the class and the case needs no version of its own.
  #
  # The homeserver names a new user after their localpart, so the profile has something in it without this having to set it the way the version under test happens to set things.
  it "can getUserProfile" do
    expect(client.profile.get_user_profile(self.user_id).displayname).to be == self.username
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Profile::CASES
end
