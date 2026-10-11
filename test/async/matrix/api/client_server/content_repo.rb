# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/content_repo"

describe Async::Matrix::ClientServer::ContentRepo do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  let(:uploaded) {client.content_repo.upload_content("the bytes of a file", "text/plain", filename: "a.txt")}

  let(:located) {uploaded.content_uri.delete_prefix("mxc://").split("/")}

  # Six of the eight operations are in every version, so their methods are on the class rather than in a layer.
  it "can uploadContent" do
    expect(uploaded.content_uri).to be =~ %r{\Amxc://}
  end

  it "can getConfig" do
    expect(client.content_repo.get_config.upload_size).to be > 0
  end

  # Whether the endpoints which do not authenticate serve anything is a question of which homeserver answers, so those two cases are layered. {Async::Matrix::ClientServer::AuthedContentRepo} is where the bytes come back once they stop.
  it "can getContentThumbnail" do
    server_name, media_id = located

    expect do
      client.content_repo.get_content_thumbnail(server_name, media_id, 32, 32, method: "scale")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The rig does not fetch pages, so the homeserver does not answer for a URL at all.
  it "can getUrlPreview" do
    expect do
      client.content_repo.get_url_preview("http://example.com")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::ContentRepo::CASES

  # The endpoints which do not authenticate, for as long as a homeserver serves them:
  include Async::Matrix::Testing::Abstract::ClientServer::UnauthenticatedContent::CASES
end
