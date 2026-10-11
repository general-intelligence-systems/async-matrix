# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::AuthedContentRepo}.
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
            # A file, by the server and the ID its `mxc://` URI names.
            #
            # @parameter server_name [String] the homeserver which holds the file.
            # @parameter media_id [String] the file itself.
            # @parameter timeout_ms [Integer | nil] how long to wait for another homeserver to answer.
            # @returns [Content] the bytes.
            def get_content_authed(server_name, media_id, timeout_ms: nil, &block)
              parameters = {timeout_ms: timeout_ms}.compact

              api::Content.get(@resource.with(path: self.path_for("download", server_name, media_id), parameters: parameters), &block)
            end

            # A file, under a name of the caller's choosing.
            #
            # @parameter server_name [String] the homeserver which holds the file.
            # @parameter media_id [String] the file itself.
            # @parameter file_name [String] the name to ask for it under.
            # @parameter timeout_ms [Integer | nil] how long to wait for another homeserver to answer.
            # @returns [Content] the bytes.
            def get_content_override_name_authed(server_name, media_id, file_name, timeout_ms: nil, &block)
              parameters = {timeout_ms: timeout_ms}.compact
              path = "#{self.path_for("download", server_name, media_id)}/#{::Protocol::URL::Encoding.escape(file_name)}"

              api::Content.get(@resource.with(path: path, parameters: parameters), &block)
            end

            # A thumbnail of a file.
            #
            # @parameter server_name [String] the homeserver which holds the file.
            # @parameter media_id [String] the file itself.
            # @parameter width [Integer] the width wanted, in pixels.
            # @parameter height [Integer] the height wanted, in pixels.
            # @parameter method [String | nil] `crop` or `scale`.
            # @parameter animated [Boolean | nil] whether an animated file may answer with an animation.
            # @parameter timeout_ms [Integer | nil] how long to wait for another homeserver to answer.
            # @returns [Content] the bytes of the thumbnail.
            def get_content_thumbnail_authed(server_name, media_id, width, height, method: nil, animated: nil, timeout_ms: nil, &block)
              parameters = {width: width, height: height, method: method, animated: animated, timeout_ms: timeout_ms}.compact

              api::Content.get(@resource.with(path: self.path_for("thumbnail", server_name, media_id), parameters: parameters), &block)
            end

            # What this homeserver will accept.
            #
            # @returns [MediaConfig] the limits it sets.
            def get_config_authed
              api::MediaConfig.get(@resource.with(path: "#{V1}/media/config"))
            end

            # What the homeserver finds at a URL, so that a client can show it.
            #
            # @parameter url [String] the page to look at.
            # @parameter ts [Integer | nil] the moment to look at it as of, in milliseconds.
            # @returns [UrlPreview] what it found.
            def get_url_preview_authed(url, ts: nil)
              parameters = {url: url, ts: ts}.compact

              api::UrlPreview.get(@resource.with(path: "#{V1}/media/preview_url", parameters: parameters))
            end

            # @parameter kind [String] `download` or `thumbnail`.
            # @parameter server_name [String] the homeserver which holds the file.
            # @parameter media_id [String] the file itself.
            # @returns [String] the path of that file.
            def path_for(kind, server_name, media_id)
              parts = [server_name, media_id].map{|part| ::Protocol::URL::Encoding.escape(part)}

              "#{V1}/media/#{kind}/#{parts.join("/")}"
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
