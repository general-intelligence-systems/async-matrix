# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "base64"

require "async/matrix/operations_context"

# Cases for the authenticated media operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::AuthedContentRepo}.
          module AuthedContentRepo
            # No changes in v1.19.
            module V1_19
            end

            # No changes in v1.18.
            module V1_18
            end

            # No changes in v1.17.
            module V1_17
            end

            # No changes in v1.16.
            module V1_16
            end

            # No changes in v1.15.
            module V1_15
            end

            # No changes in v1.14.
            module V1_14
            end

            # No changes in v1.13.
            module V1_13
            end

            # No changes in v1.12.
            module V1_12
            end

            # v1.11 added the media endpoints which authenticate.
            module V1_11
              # The smallest image a homeserver will make a thumbnail of, since a thumbnail of text is not a thumbnail.
              PNG = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQAY3Y2wAAAAAElFTkSuQmCC")

              def self.included(base)
                base.let(:uploaded){client.content_repo.upload_content("the bytes of a file", "text/plain", filename: "a.txt")}

                base.let(:located){uploaded.content_uri.delete_prefix("mxc://").split("/")}

                base.let(:image){client.content_repo.upload_content(PNG, "image/png", filename: "dot.png").content_uri.delete_prefix("mxc://").split("/")}

                base.it "can getContentAuthed" do
                  server_name, media_id = located

                  content = client.authed_content_repo.get_content_authed(server_name, media_id)

                  expect(content.bytes).to be == "the bytes of a file"
                  expect(content.content_type).to be =~ %r{\Atext/plain}
                end

                # The bytes come back as they were sent, which for an image means byte for byte.
                base.it "answers with the bytes which were uploaded" do
                  server_name, media_id = image

                  expect(client.authed_content_repo.get_content_authed(server_name, media_id).bytes).to be == PNG
                end

                # A file is as large as it is: given a block, the bytes arrive a chunk at a time, so nothing holds the whole of it.
                base.it "streams the bytes where it is given a block" do
                  large = client.content_repo.upload_content("x" * 200_000, "application/octet-stream", filename: "big.bin")
                  server_name, media_id = large.content_uri.delete_prefix("mxc://").split("/")

                  chunks = []

                  client.authed_content_repo.get_content_authed(server_name, media_id) do |_resource, response, _klass|
                    response.body.each{|chunk| chunks << chunk.bytesize}
                  end

                  expect(chunks.size).to be > 1
                  expect(chunks.sum).to be == 200_000
                end

                base.it "can getContentOverrideNameAuthed" do
                  server_name, media_id = located

                  content = client.authed_content_repo.get_content_override_name_authed(server_name, media_id, "renamed.txt")

                  expect(content.bytes).to be == "the bytes of a file"
                  expect(content.content_disposition).to be =~ /renamed\.txt/
                end

                base.it "can getContentThumbnailAuthed" do
                  server_name, media_id = image

                  thumbnail = client.authed_content_repo.get_content_thumbnail_authed(server_name, media_id, 32, 32, method: "scale")

                  expect(thumbnail.content_type).to be == "image/png"
                  expect(thumbnail.size).to be > 0
                end

                # A URI reserved by v1.7 and never filled in is held rather than denied, and this is the first version which can read it back.
                base.it "says the bytes of a reserved URI have not arrived" do
                  created = client.content_repo.create_content
                  server_name, media_id = created.content_uri.delete_prefix("mxc://").split("/")

                  error = nil

                  begin
                    client.authed_content_repo.get_content_authed(server_name, media_id)
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error.errcode).to be == "M_NOT_YET_UPLOADED"
                end

                base.it "can getConfigAuthed" do
                  expect(client.authed_content_repo.get_config_authed.upload_size).to be > 0
                end

                # The rig does not fetch pages, so the homeserver does not answer for a URL at all.
                base.it "can getUrlPreviewAuthed" do
                  expect do
                    client.authed_content_repo.get_url_preview_authed("http://example.com")
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # No changes in v1.10.
            module V1_10
            end

            # No changes in v1.9.
            module V1_9
            end

            # No changes in v1.8.
            module V1_8
            end

            # No changes in v1.7.
            module V1_7
            end

            # No changes in v1.6.
            module V1_6
            end

            # No changes in v1.5.
            module V1_5
            end

            # No changes in v1.4.
            module V1_4
            end

            # No changes in v1.3.
            module V1_3
            end

            # No changes in v1.2.
            module V1_2
            end

            # No changes in v1.1.
            module V1_1
            end
            # The cases required at the version under test.
            CASES = Sus::Shared("authenticated media cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if AuthedContentRepo.const_defined?(name, false)
                  include AuthedContentRepo.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
