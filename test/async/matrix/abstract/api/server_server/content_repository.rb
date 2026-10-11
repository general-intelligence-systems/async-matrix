# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the files another server holds, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::ContentRepository}.
          module ContentRepository
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

            # v1.11 moved media behind authentication.
            module V1_11
              def self.included(base)
                # A file is uploaded through the client, which is the only way to put one there.
                base.let(:uploaded){client.content_repo.upload_content(Async::Matrix::TEST_IMAGE, "image/png", filename: "test.png")}

                base.let(:media_id){uploaded.content_uri.split("/").last}

                base.it "can getContent" do
                  content = server.content_repository.get_content(media_id)

                  expect(content.bytes).to be == Async::Matrix::TEST_IMAGE
                  expect(content.content_type).to be == "image/png"
                end

                # The first part describes the file, and is a document even when it says nothing.
                base.it "reads what the server says about the file" do
                  expect(server.content_repository.get_content(media_id).description).to be_a(Hash)
                end

                base.it "can getContentThumbnail" do
                  thumbnail = server.content_repository.get_content_thumbnail(media_id, 32, 32, method: "crop")

                  expect(thumbnail.size).to be > 0
                  expect(thumbnail.content_type).to be(:start_with?, "image/")
                end

                # A thumbnail is smaller than what it is a thumbnail of, which is the point of it.
                base.it "sends a thumbnail smaller than the file" do
                  thumbnail = server.content_repository.get_content_thumbnail(media_id, 32, 32, method: "crop")

                  expect(thumbnail.size).to be < Async::Matrix::TEST_IMAGE.bytesize
                end

                base.it "carried the file rather than pointing elsewhere" do
                  expect(server.content_repository.get_content(media_id)).not.to be(:redirected?)
                end

                base.it "refuses a file it does not hold" do
                  expect do
                    server.content_repository.get_content("nothing-at-all").bytes
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
            CASES = Sus::Shared("content repository cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if ContentRepository.const_defined?(name, false)
                  include ContentRepository.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
