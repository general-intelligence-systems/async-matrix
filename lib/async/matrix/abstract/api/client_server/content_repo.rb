# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::ContentRepo}.
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

          # No changes in v1.12.
          module V1_12
          end

          # v1.11 added `animated` to the thumbnail query.
          module V1_11
            # A thumbnail of a file.
            #
            # @parameter server_name [String] the homeserver which holds the file.
            # @parameter media_id [String] the file itself.
            # @parameter width [Integer] the width wanted, in pixels.
            # @parameter height [Integer] the height wanted, in pixels.
            # @parameter method [String | nil] `crop` or `scale`.
            # @parameter allow_remote [Boolean | nil] whether the homeserver may fetch it from another.
            # @parameter allow_redirect [Boolean | nil] whether the homeserver may answer with a redirect instead of the bytes.
            # @parameter animated [Boolean | nil] whether an animated file may answer with an animation.
            # @parameter timeout_ms [Integer | nil] how long to wait for another homeserver to answer.
            # @yields {|resource, response, klass| ...} the response, where a block is given, while the body is still arriving.
            # @returns [Content] the bytes of the thumbnail, where no block is given.
            def get_content_thumbnail(server_name, media_id, width, height, method: nil, allow_remote: nil, allow_redirect: nil, animated: nil, timeout_ms: nil, &block)
              parameters = {width: width, height: height, method: method, allow_remote: allow_remote, allow_redirect: allow_redirect, animated: animated, timeout_ms: timeout_ms}.compact

              api::Content.get(@resource.with(path: self.class.path_for("thumbnail", server_name, media_id), parameters: parameters), &block)
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
            # Reserve a `mxc://` URI, which an upload fills in later.
            #
            # @returns [CreatedContent] the URI, and how long it is held.
            def create_content
              api::CreatedContent.post(@resource.with(path: "#{MEDIA_V1}/create"), {})
            end

            # Upload the bytes of a URI which was reserved.
            #
            # @parameter server_name [String] the homeserver which reserved it.
            # @parameter media_id [String] the URI reserved.
            # @parameter content [String] the bytes to upload.
            # @parameter content_type [String] what the bytes are, e.g. `text/plain`.
            # @parameter filename [String | nil] the name to give the file.
            # @returns [Representation] the empty response.
            def upload_content_to_mxc(server_name, media_id, content, content_type, filename: nil)
              parameters = {filename: filename}.compact
              parts = [server_name, media_id].map{|part| ::Protocol::URL::Encoding.escape(part)}
              resource = @resource.with(path: "#{self.class.path}/#{parts.join("/")}", parameters: parameters, headers: {"content-type" => content_type})

              api::Uploaded.put(resource, content)
            end

            # A file, by the server and the ID its `mxc://` URI names.
            #
            # @parameter server_name [String] the homeserver which holds the file.
            # @parameter media_id [String] the file itself.
            # @parameter allow_remote [Boolean | nil] whether the homeserver may fetch it from another.
            # @parameter allow_redirect [Boolean | nil] whether the homeserver may answer with a redirect instead of the bytes.
            # @parameter timeout_ms [Integer | nil] how long to wait for another homeserver to answer.
            # @yields {|resource, response, klass| ...} the response, where a block is given, while the body is still arriving.
            # @returns [Content] the bytes, where no block is given.
            def get_content(server_name, media_id, allow_remote: nil, allow_redirect: nil, timeout_ms: nil, &block)
              parameters = {allow_remote: allow_remote, allow_redirect: allow_redirect, timeout_ms: timeout_ms}.compact

              api::Content.get(@resource.with(path: self.class.path_for("download", server_name, media_id), parameters: parameters), &block)
            end

            # A file, under a name of the caller's choosing.
            #
            # @parameter server_name [String] the homeserver which holds the file.
            # @parameter media_id [String] the file itself.
            # @parameter file_name [String] the name to ask for it under.
            # @parameter allow_remote [Boolean | nil] whether the homeserver may fetch it from another.
            # @parameter allow_redirect [Boolean | nil] whether the homeserver may answer with a redirect instead of the bytes.
            # @parameter timeout_ms [Integer | nil] how long to wait for another homeserver to answer.
            # @yields {|resource, response, klass| ...} the response, where a block is given, while the body is still arriving.
            # @returns [Content] the bytes, where no block is given.
            def get_content_override_name(server_name, media_id, file_name, allow_remote: nil, allow_redirect: nil, timeout_ms: nil, &block)
              parameters = {allow_remote: allow_remote, allow_redirect: allow_redirect, timeout_ms: timeout_ms}.compact
              path = "#{self.class.path_for("download", server_name, media_id)}/#{::Protocol::URL::Encoding.escape(file_name)}"

              api::Content.get(@resource.with(path: path, parameters: parameters), &block)
            end

            # A thumbnail of a file.
            #
            # @parameter server_name [String] the homeserver which holds the file.
            # @parameter media_id [String] the file itself.
            # @parameter width [Integer] the width wanted, in pixels.
            # @parameter height [Integer] the height wanted, in pixels.
            # @parameter method [String | nil] `crop` or `scale`.
            # @parameter allow_remote [Boolean | nil] whether the homeserver may fetch it from another.
            # @parameter allow_redirect [Boolean | nil] whether the homeserver may answer with a redirect instead of the bytes.
            # @parameter timeout_ms [Integer | nil] how long to wait for another homeserver to answer.
            # @yields {|resource, response, klass| ...} the response, where a block is given, while the body is still arriving.
            # @returns [Content] the bytes of the thumbnail, where no block is given.
            def get_content_thumbnail(server_name, media_id, width, height, method: nil, allow_remote: nil, allow_redirect: nil, timeout_ms: nil, &block)
              parameters = {width: width, height: height, method: method, allow_remote: allow_remote, allow_redirect: allow_redirect, timeout_ms: timeout_ms}.compact

              api::Content.get(@resource.with(path: self.class.path_for("thumbnail", server_name, media_id), parameters: parameters), &block)
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
        end

        # Layers for {ruby Async::Matrix::ClientServer::CreatedContent}.
        module CreatedContent
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

          # v1.7 added the reservation, which names the URI it held.
          module V1_7
            # @returns [String] the `mxc://` URI which was reserved.
            def content_uri
              self.value[:content_uri]
            end

            # @returns [Integer | nil] when the reservation lapses, in milliseconds since the epoch.
            def unused_expires_at
              self.value[:unused_expires_at]
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
        end
      end
    end
  end
end
