# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the media operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::ContentRepo}.
          module ContentRepo
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

            # v1.12 runs Synapse 1.135.0, which authenticates media.
            module V1_12
              def self.included(base)
                # The endpoints which do not authenticate are answered with nothing from here on, so the cases assert the refusal instead. The request is still the one the specification describes.
                base.it "can getContent" do
                  server_name, media_id = located

                  error = nil

                  begin
                    client.content_repo.get_content(server_name, media_id)
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error.errcode).to be == "M_NOT_FOUND"
                end

                base.it "can getContentOverrideName" do
                  server_name, media_id = located

                  expect do
                    client.content_repo.get_content_override_name(server_name, media_id, "renamed.txt")
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # v1.11 added `animated` to the thumbnail query.
            module V1_11
              def self.included(base)
                base.it "can getContentThumbnail with animated" do
                  server_name, media_id = located

                  expect do
                    client.content_repo.get_content_thumbnail(server_name, media_id, 32, 32, method: "scale", animated: true)
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

            # v1.7 added reserving a URI, and widened the download queries.
            module V1_7
              def self.included(base)
                base.it "can createContent" do
                  created = client.content_repo.create_content

                  expect(created.content_uri).to be =~ %r{\Amxc://}
                  expect(created.unused_expires_at).to be_a(Integer)
                end

                base.it "can uploadContentToMXC" do
                  created = client.content_repo.create_content
                  server_name, media_id = created.content_uri.delete_prefix("mxc://").split("/")

                  expect(client.content_repo.upload_content_to_mxc(server_name, media_id, "the reserved bytes", "text/plain").value).to be == {}
                end

                base.it "can getContentThumbnail with allow_redirect and timeout_ms" do
                  server_name, media_id = located

                  expect do
                    client.content_repo.get_content_thumbnail(server_name, media_id, 32, 32, method: "scale", allow_redirect: true, timeout_ms: 5000)
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
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
            CASES = Sus::Shared("media cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if ContentRepo.const_defined?(name, false)
                  include ContentRepo.const_get(name, false)
                end
              end
            end
          end

          # Cases for the endpoints which do not authenticate.
          module UnauthenticatedContent
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

            # No changes in v1.11.
            module V1_11
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

            # v1.1 serves the bytes without authentication.
            module V1_1
              # v1.12 answers with nothing instead, and the refusal is asserted by {ContentRepo} from there.
              WITHDRAWN_IN = "v1.12"

              def self.included(base)
                base.it "can getContent" do
                  server_name, media_id = located

                  expect(client.content_repo.get_content(server_name, media_id).bytes).to be == "the bytes of a file"
                end

                base.it "can getContentOverrideName" do
                  server_name, media_id = located

                  expect(client.content_repo.get_content_override_name(server_name, media_id, "renamed.txt").bytes).to be == "the bytes of a file"
                end
              end
            end

            # The cases required at the version under test.
            #
            # The layer names the version which stopped serving it and is left out from there, so that each operation has exactly one case at every version.
            CASES = Sus::Shared("unauthenticated media cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if UnauthenticatedContent.const_defined?(name, false)
                  layer = UnauthenticatedContent.const_get(name, false)

                  if layer.const_defined?(:WITHDRAWN_IN, false) and Async::Matrix::Versions.up_to(Async::Matrix::TEST_VERSION).include?(layer::WITHDRAWN_IN)
                    next
                  end

                  include layer
                end
              end
            end
          end
        end
      end
    end
  end
end
