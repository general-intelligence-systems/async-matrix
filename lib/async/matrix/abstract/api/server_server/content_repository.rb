# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::ContentRepository}.
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
            # A file another server holds, as the two part answer the endpoint sends.
            #
            # @parameter media_id [String] the file, which is the last part of its `mxc://` URI.
            # @parameter timeout_ms [Integer | nil] how long the server may spend fetching it.
            # @returns [FederatedContent] the file, and what the server says about it.
            def get_content(media_id, timeout_ms: nil)
              path = "#{FEDERATION_V1}/media/download/#{::Protocol::URL::Encoding.escape(media_id)}"
              parameters = {timeout_ms: timeout_ms}.compact

              api::FederatedContent.get(@resource.with(path: path, parameters: parameters))
            end

            # A thumbnail of a file another server holds.
            #
            # @parameter media_id [String] the file to thumbnail.
            # @parameter width [Integer] how wide the thumbnail should be.
            # @parameter height [Integer] how tall the thumbnail should be.
            # @parameter method [String | nil] `crop` to fill the box, or `scale` to fit it.
            # @parameter options [Hash] whatever else the version takes.
            # @returns [FederatedContent] the thumbnail, and what the server says about it.
            def get_content_thumbnail(media_id, width, height, method: nil, **options)
              path = "#{FEDERATION_V1}/media/thumbnail/#{::Protocol::URL::Encoding.escape(media_id)}"
              parameters = {width: width, height: height, method: method}.compact.merge(options)

              api::FederatedContent.get(@resource.with(path: path, parameters: parameters))
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
        end

        # Layers for {ruby Async::Matrix::ServerServer::FederatedContent}.
        module FederatedContent
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

          # v1.11 answered in two parts rather than bytes.
          module V1_11
            # @returns [String | nil] the bytes of the file, where the answer carried them.
            def bytes
              self.value[:bytes]
            end

            # What the first part says about the file, which is a document of its own.
            #
            # @returns [Hash] what the server says.
            def description
              self.value[:metadata] || {}
            end

            # @returns [String | nil] what the server says the bytes are, e.g. `image/png`.
            def content_type
              self.value[:content_type]
            end

            # @returns [String | nil] the name the server suggests for the file.
            def content_disposition
              self.value[:content_disposition]
            end

            # The second part may say where the file is instead of carrying it.
            #
            # @returns [String | nil] where to fetch it from.
            def location
              self.value[:location]
            end

            # @returns [Boolean] whether the answer pointed elsewhere rather than carrying the file.
            def redirected?
              !self.location.nil?
            end

            # @returns [Integer] how many bytes came back.
            def size
              self.bytes.to_s.bytesize
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
        end
      end
    end
  end
end
