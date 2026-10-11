# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identity_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/identity/v2_email_associations"

describe Async::Matrix::Identity::V2EmailAssociations do
  include Async::Matrix::IdentityContext
  include Async::Matrix::OperationsContext

  # The rig has no mail, so the server cannot send a token for the user to read.
  it "can emailRequestTokenV2" do
    error = nil

    begin
      identity.v2_email_associations.email_request_token_v2("a-secret", "nobody@example.com")
    rescue Async::Matrix::RequestError => error
    end

    expect(error.errcode).to be == "M_EMAIL_SEND_ERROR"
  end

  # The link in the message is followed by a browser, so the server answers with a page rather than a document.
  it "can emailSubmitTokenGetV2" do
    page = unauthenticated.v2_email_associations.email_submit_token_get_v2("a-session", "a-secret", "a-token")

    expect(page.content_type).to be =~ %r{text/html}
    expect(page.bytes).to be =~ /Verification/
  end

  # A token which was never sent is not one which matches, which the server reports in the answer rather than as a refusal.
  it "can emailSubmitTokenPostV2" do
    expect(identity.v2_email_associations.email_submit_token_post_v2("a-session", "a-secret", "a-token")).not.to be(:success?)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::Identity::V2EmailAssociations::CASES
end
